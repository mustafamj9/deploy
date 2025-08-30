# --- Authenticate to Azure using Managed Identity ---
Write-Output "Logging in to Azure.."
Connect-AzAccount -Identity | Out-Null
Write-Output "Connected to Azure using automation account's Managed Identity"

$ErrorActionPreference = "Stop"
$VerbosePreference     = "Continue"

# --- Automation Account Variables ---
$SourceAccountName  = Get-AutomationVariable -Name "SourceAccountName"
$SourceAccountKey   = Get-AutomationVariable -Name "SourceAccountKey"
$DestAccountName    = Get-AutomationVariable -Name "DestAccountName"
$DestAccountKey     = Get-AutomationVariable -Name "DestAccountKey"
$ShareName          = Get-AutomationVariable -Name "ShareName"
$BasePath           = Get-AutomationVariable -Name "BasePath"

Write-Output "Using Source=$SourceAccountName, Dest=$DestAccountName, Share=$ShareName, Path=$BasePath"

# --- Storage Contexts ---
$srcCtx  = New-AzStorageContext -StorageAccountName $SourceAccountName -StorageAccountKey $SourceAccountKey
$destCtx = New-AzStorageContext -StorageAccountName $DestAccountName   -StorageAccountKey $DestAccountKey

# --- Counters ---
$global:FilesCopied   = 0
$global:FilesDeleted  = 0
$global:DirsDeleted   = 0

# --- Ensure destination share & base folder exist ---
if (-not (Get-AzStorageShare -Context $destCtx -Name $ShareName -ErrorAction SilentlyContinue)) {
  Write-Output "Creating destination share '$ShareName'..."
  New-AzStorageShare -Context $destCtx -Name $ShareName | Out-Null
}
New-AzStorageDirectory -Context $destCtx -ShareName $ShareName -Path $BasePath -ErrorAction SilentlyContinue | Out-Null

# --- Helpers ---
function Ensure-DestDirectory([string]$RelativePath) { 
  if ($RelativePath) { New-AzStorageDirectory -Context $destCtx -ShareName $ShareName -Path $RelativePath -ErrorAction SilentlyContinue | Out-Null }
}
function Get-Children([string]$RelPath, $ctx) { (Get-AzStorageFile -ShareName $ShareName -Path $RelPath -Context $ctx) | Get-AzStorageFile -Context $ctx }
function Is-Directory($item) { $item.GetType().Name -like '*Directory*' }
function Is-File($item)      { $item.GetType().Name -like '*File' -and -not (Is-Directory $item) }

# --- Recursive Copy ---
function Copy-UnderBase([string]$CurrentPath) {
  foreach ($child in Get-Children $CurrentPath $srcCtx) {
    if (Is-Directory $child) {
      $childPath = "$CurrentPath/$($child.Name)"
      Ensure-DestDirectory $childPath
      Copy-UnderBase $childPath
    }
    elseif (Is-File $child) {
      $fileRel = "$CurrentPath/$($child.Name)"
      Ensure-DestDirectory (Split-Path $fileRel -Parent)
      Write-Output "Copying '$fileRel' ..."
      Start-AzStorageFileCopy -SrcShareName $ShareName -SrcFilePath $fileRel -Context $srcCtx `
                              -DestShareName $ShareName -DestFilePath $fileRel -DestContext $destCtx -Force | Out-Null
      $global:FilesCopied++
    }
  }
}

# --- Recursive Delete (dir + children) ---
function Remove-DirectoryRecursive([string]$RelPath) {
  foreach ($child in Get-Children $RelPath $destCtx) {
    $childPath = "$RelPath/$($child.Name)"
    if (Is-Directory $child) { Remove-DirectoryRecursive $childPath }
    elseif (Is-File $child)  { Write-Output "Deleting file '$childPath' ..."; Remove-AzStorageFile -ShareName $ShareName -Path $childPath -Context $destCtx; $global:FilesDeleted++ }
  }
  Write-Output "Deleting directory '$RelPath' ..."
  Remove-AzStorageDirectory -ShareName $ShareName -Path $RelPath -Context $destCtx
  $global:DirsDeleted++
}

# --- Cleanup stale files/dirs in dest ---
function Cleanup-UnderBase([string]$CurrentPath) {
  foreach ($dChild in Get-Children $CurrentPath $destCtx) {
    $dRelPath = "$CurrentPath/$($dChild.Name)"
    if (Is-Directory $dChild) {
      if (-not (Get-AzStorageFile -ShareName $ShareName -Path $dRelPath -Context $srcCtx -ErrorAction SilentlyContinue)) {
        Write-Output "Removing stale directory '$dRelPath' recursively ..."
        Remove-DirectoryRecursive $dRelPath
      } else { Cleanup-UnderBase $dRelPath }
    }
    elseif (Is-File $dChild) {
      if (-not (Get-AzStorageFile -ShareName $ShareName -Path $dRelPath -Context $srcCtx -ErrorAction SilentlyContinue)) {
        Write-Output "Removing stale file '$dRelPath' ..."
        Remove-AzStorageFile -ShareName $ShareName -Path $dRelPath -Context $destCtx
        $global:FilesDeleted++
      }
    }
  }
}

# --- Run Sync with Validation ---
try {
    # validate source base path exists
    $null = Get-AzStorageFile -ShareName $ShareName -Path $BasePath -Context $srcCtx -ErrorAction Stop
    Write-Output "Starting sync from '$SourceAccountName/$ShareName/$BasePath' to '$DestAccountName/$ShareName/$BasePath' ..."
    Copy-UnderBase $BasePath
    Cleanup-UnderBase $BasePath

    # --- Final Summary ---
    Write-Output "✅ Sync complete for '$BasePath'"
    Write-Output "Summary: $global:FilesCopied files copied, $global:FilesDeleted files deleted, $global:DirsDeleted directories deleted."
}
catch {
    Write-Output "❌ ERROR: Could not access source '$SourceAccountName/$ShareName/$BasePath'."
    Write-Output "Reason: $($_.Exception.Message)"
    throw  # rethrow so the Automation job fails cleanly
}
