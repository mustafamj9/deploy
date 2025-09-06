param(
    [switch]$Apply,                     # run with -Apply to actually write files
    [string]$AllowedUser = "$env:USERNAME"  # default: only allow the current user; change if needed
)

# quick safety: only allow a specific user to run the destructive action
if ($env:USERNAME -ne $AllowedUser) {
    Write-Warning "This script can only be run by user '$AllowedUser'. Current user: $env:USERNAME. Exiting."
    exit 1
}

# files to update (edit as needed)
$files = @(
    'D:\property\yoyoyoy.txt',
    'D:\gymflow-membership-nexus\backend\db.js'
)

$backupRoot = 'E:\software\backup'
if (-not (Test-Path -LiteralPath $backupRoot)) { New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null }

Write-Host "Files that would be processed:"
$files | ForEach-Object { Write-Host " - $_" }

if (-not $Apply) {
    Write-Host ""
    Write-Host "DRY RUN (no changes). To apply changes, re-run with the -Apply switch."
    exit 0
}

# final interactive confirmation before any destructive action
$consent = Read-Host "You passed -Apply. Type 'YES' (all caps) to confirm you want to proceed and modify files"
if ($consent -ne 'YES') {
    Write-Host "Confirmation not received. Exiting without changes."
    exit 0
}

foreach ($filePath in $files) {
    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
        Write-Warning "File not found, skipping: $filePath"
        continue
    }

    # timestamped backup
    $timeStamp  = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $backupPath = Join-Path $backupRoot ((Split-Path $filePath -Leaf) + ".$timeStamp.bak")
    Copy-Item -LiteralPath $filePath -Destination $backupPath -Force
    Write-Host "Backup created: $backupPath"

    # read full file
    $content = Get-Content -LiteralPath $filePath -Raw

    if ($filePath -like '*.env' -or $filePath -like '*.txt') {
        # for env/txt → replace only in value side
        $lines = $content -split "`r?`n"
        $updatedLines = foreach ($line in $lines) {
            if ($line -match '^(.*?=)(.*)$') {
                $left  = $matches[1]
                $right = $matches[2]
                $newRight = [regex]::Replace($right, 'muscle', 'plzz', 'IgnoreCase')
                "$left$newRight"
            } else { $line }
        }
        $updatedContent = $updatedLines -join "`r`n"
    }
    else {
        # for db.js or any other → replace every "muscle" with "plzz"
        $updatedContent = [regex]::Replace($content, 'muscle', 'plzz', 'IgnoreCase')
    }

    # write back
    Set-Content -LiteralPath $filePath -Value $updatedContent -Encoding UTF8
    Write-Host "Updated: $filePath"
}

Write-Host "All done. Backups saved in $backupRoot"
