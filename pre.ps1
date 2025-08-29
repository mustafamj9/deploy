$ErrorActionPreference = "Stop"
$VerbosePreference     = "Continue"

# --- YOUR VALUES (from chat) ---
$SourceAccountName  = ''
$SourceAccountKey   = ''

$DestAccountName    = ''
$DestAccountKey     = ''

$ShareName          = 'name'
$BasePath           = 'main/test'   # <-- we copy everything under this folder

# --- Contexts ---
$srcCtx  = New-AzStorageContext -StorageAccountName $SourceAccountName -StorageAccountKey $SourceAccountKey
$destCtx = New-AzStorageContext -StorageAccountName $DestAccountName   -StorageAccountKey $DestAccountKey

# --- Ensure destination share & base folder exist ---
if (-not (Get-AzStorageShare -Context $destCtx -Name $ShareName -ErrorAction SilentlyContinue)) {
  Write-Verbose "Creating destination share '$ShareName'..."
  New-AzStorageShare -Context $destCtx -Name $ShareName | Out-Null
}
# Ensure 'main' exists on destination
New-AzStorageDirectory -Context $destCtx -ShareName $ShareName -Path $BasePath -ErrorAction SilentlyContinue | Out-Null

# --- Helpers ---
function Ensure-DestDirectory([string]$RelativePath) {
  if ([string]::IsNullOrWhiteSpace($RelativePath)) { return }
  New-AzStorageDirectory -Context $destCtx -ShareName $ShareName -Path $RelativePath -ErrorAction SilentlyContinue | Out-Null
}

function Get-Children([string]$RelPath) {
  # List children of the given directory path using pipeline style (works across Az.Storage versions)
  $dir = Get-AzStorageFile -ShareName $ShareName -Path $RelPath -Context $srcCtx
  return $dir | Get-AzStorageFile -Context $srcCtx
}

# Robust type checks across Az.Storage versions
function Is-Directory($item) { return ($item.GetType().Name -like '*Directory*') }
function Is-File($item)      { return ($item.GetType().Name -like '*File' -and -not (Is-Directory $item)) }

function Copy-UnderBase([string]$CurrentPath) {
  # $CurrentPath is always a subpath under $BasePath (e.g., 'main', 'main/dcs', ...)
  $children = Get-Children $CurrentPath

  foreach ($child in $children) {
    if (Is-Directory $child) {
      $name       = $child.Name
      $childPath  = "$CurrentPath/$name"   # still under 'main/...'
      Ensure-DestDirectory $childPath
      Copy-UnderBase $childPath
    }
    elseif (Is-File $child) {
      $fileRel = "$CurrentPath/$($child.Name)"  # e.g., 'main/file.txt' or 'main/dcs/a.txt'
      $parent  = Split-Path $fileRel -Parent
      if ($parent) { Ensure-DestDirectory $parent }

      Write-Verbose "Copying '$fileRel' ..."
      Start-AzStorageFileCopy `
        -SrcShareName  $ShareName -SrcFilePath  $fileRel -Context $srcCtx `
        -DestShareName $ShareName -DestFilePath $fileRel -DestContext $destCtx `
        -Force | Out-Null
    }
  }
}

# --- Validate source base folder exists ---
$null = Get-AzStorageFile -ShareName $ShareName -Path $BasePath -Context $srcCtx  # throws 404 if missing

Write-Verbose "Copying CONTENTS of '$SourceAccountName/$ShareName/$BasePath' to '$DestAccountName/$ShareName/$BasePath' ..."
Copy-UnderBase $BasePath
Write-Host "✅ All copy operations submitted for '$BasePath/*'. (Server-side copies will continue in Azure.)"

# --- Optional: uncomment to wait for each file to complete before finishing
# After Start-AzStorageFileCopy above, insert:
# $destFile = Get-AzStorageFile -Context $destCtx -ShareName $ShareName -Path $fileRel
# do { Start-Sleep -Seconds 2; $state = Get-AzStorageFileCopyState -File $destFile } while ($state.Status -eq "Pending")
# if ($state.Status -ne "Success") { throw "Copy failed for $fileRel: $($state.StatusDescription)" }
