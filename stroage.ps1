# ============================================================
# Azure Automation Runbook
# File Share Sync (SRC ➜ DEST) | Multiple Storage Pairs
# ============================================================

Write-Output "🔐 Logging in to Azure using Managed Identity..."
Connect-AzAccount -Identity | Out-Null
Write-Output "✅ Connected to Azure"

$ErrorActionPreference = "Stop"
$VerbosePreference     = "Continue"

# ------------------------------------------------------------
# Common Settings
# ------------------------------------------------------------
$ShareName = "vision"
$BasePath  = "main"

# ------------------------------------------------------------
# Read Automation Variables
# ------------------------------------------------------------
$StoragePairs = @(
    @{
        SourceAccountName = Get-AutomationVariable -Name "SourceAccountName1"
        SourceAccountKey  = Get-AutomationVariable -Name "SourceAccountKey1"
        DestAccountName   = Get-AutomationVariable -Name "DescAccountName1"
        DestAccountKey    = Get-AutomationVariable -Name "DescAccountKey1"
    },
    @{
        SourceAccountName = Get-AutomationVariable -Name "SourceAccountName2"
        SourceAccountKey  = Get-AutomationVariable -Name "SourceAccountKey2"
        DestAccountName   = Get-AutomationVariable -Name "DescAccountName2"
        DestAccountKey    = Get-AutomationVariable -Name "DescAccountKey2"
    }
)

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

function Ensure-DestDirectory([string]$RelativePath) {
    if ($RelativePath) {
        New-AzStorageDirectory -Context $destCtx -ShareName $ShareName -Path $RelativePath -ErrorAction SilentlyContinue | Out-Null
    }
}

function Get-Children([string]$RelPath, $ctx) {
    (Get-AzStorageFile -ShareName $ShareName -Path $RelPath -Context $ctx) |
    Get-AzStorageFile -Context $ctx
}

function Is-Directory($item) { $item.GetType().Name -like "*Directory*" }
function Is-File($item) { $item.GetType().Name -like "*File*" -and -not (Is-Directory $item) }

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
            Write-Output "📄 Copying '$fileRel' ..."
            Start-AzStorageFileCopy `
                -SrcShareName $ShareName `
                -SrcFilePath  $fileRel `
                -Context      $srcCtx `
                -DestShareName $ShareName `
                -DestFilePath  $fileRel `
                -DestContext   $destCtx `
                -Force | Out-Null
            $global:FilesCopied++
        }
    }
}

function Remove-DirectoryRecursive([string]$RelPath) {
    foreach ($child in Get-Children $RelPath $destCtx) {
        $childPath = "$RelPath/$($child.Name)"
        if (Is-Directory $child) {
            Remove-DirectoryRecursive $childPath
        }
        elseif (Is-File $child) {
            Write-Output "🗑 Deleting file '$childPath'"
            Remove-AzStorageFile -ShareName $ShareName -Path $childPath -Context $destCtx
            $global:FilesDeleted++
        }
    }
    Write-Output "🗑 Deleting directory '$RelPath'"
    Remove-AzStorageDirectory -ShareName $ShareName -Path $RelPath -Context $destCtx
    $global:DirsDeleted++
}

function Cleanup-UnderBase([string]$CurrentPath) {
    foreach ($dChild in Get-Children $CurrentPath $destCtx) {
        $dRelPath = "$CurrentPath/$($dChild.Name)"
        if (Is-Directory $dChild) {
            if (-not (Get-AzStorageFile -ShareName $ShareName -Path $dRelPath -Context $srcCtx -ErrorAction SilentlyContinue)) {
                Remove-DirectoryRecursive $dRelPath
            }
            else {
                Cleanup-UnderBase $dRelPath
            }
        }
        elseif (Is-File $dChild) {
            if (-not (Get-AzStorageFile -ShareName $ShareName -Path $dRelPath -Context $srcCtx -ErrorAction SilentlyContinue)) {
                Remove-AzStorageFile -ShareName $ShareName -Path $dRelPath -Context $destCtx
                $global:FilesDeleted++
            }
        }
    }
}

# ------------------------------------------------------------
# Execute Sync for Each Storage Pair
# ------------------------------------------------------------
foreach ($pair in $StoragePairs) {

    $SourceAccountName = $pair.SourceAccountName
    $SourceAccountKey  = $pair.SourceAccountKey
    $DestAccountName   = $pair.DestAccountName
    $DestAccountKey    = $pair.DestAccountKey

    if ([string]::IsNullOrWhiteSpace($SourceAccountName) -or
        [string]::IsNullOrWhiteSpace($DestAccountName)) {
        Write-Output "⚠ Skipping empty storage pair"
        continue
    }

    Write-Output "==============================================="
    Write-Output "🔁 Syncing: $SourceAccountName ➜ $DestAccountName"
    Write-Output "==============================================="

    # Reset counters
    $global:FilesCopied  = 0
    $global:FilesDeleted = 0
    $global:DirsDeleted  = 0

    # Create contexts
    $srcCtx  = New-AzStorageContext -StorageAccountName $SourceAccountName -StorageAccountKey $SourceAccountKey
    $destCtx = New-AzStorageContext -StorageAccountName $DestAccountName   -StorageAccountKey $DestAccountKey

    try {
        # Ensure destination share & folder
        if (-not (Get-AzStorageShare -Context $destCtx -Name $ShareName -ErrorAction SilentlyContinue)) {
            New-AzStorageShare -Context $destCtx -Name $ShareName | Out-Null
        }

        New-AzStorageDirectory -Context $destCtx -ShareName $ShareName -Path $BasePath -ErrorAction SilentlyContinue | Out-Null

        # Validate source path
        $null = Get-AzStorageFile -ShareName $ShareName -Path $BasePath -Context $srcCtx -ErrorAction Stop

        # Sync
        Copy-UnderBase    $BasePath
        Cleanup-UnderBase $BasePath

        Write-Output "✅ Completed: $SourceAccountName ➜ $DestAccountName"
        Write-Output "Summary: $global:FilesCopied copied | $global:FilesDeleted deleted | $global:DirsDeleted dirs"
    }
    catch {
        Write-Output "❌ ERROR syncing $SourceAccountName ➜ $DestAccountName"
        Write-Output $_.Exception.Message
        throw
    }
}

Write-Output "🎉 All storage pairs processed successfully"
