param(
    [switch]$Apply,                     # run with -Apply to actually write files
    [string]$AllowedUser = "$env:USERNAME"  # default: only allow the current user; change if needed
)

# safety: only allow a specific user to run destructive action
if ($env:USERNAME -ne $AllowedUser) {
    Write-Warning "This script can only be run by user '$AllowedUser'. Current user: $env:USERNAME. Exiting."
    exit 1
}

# only files listed here will ever be touched
$files = @(
    'D:\property\yoyoyoy.txt',
    'D:\gymflow-membership-nexus\backend\db.js'
)

$backupRoot = 'E:\software\backup'
if (-not (Test-Path -LiteralPath $backupRoot)) {
    New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
}

Write-Host "Files that would be processed:"
$files | ForEach-Object { Write-Host " - $_" }

if (-not $Apply) {
    Write-Host ""
    Write-Host "DRY RUN (no changes). To apply changes, re-run with the -Apply switch."
    exit 0
}

# final interactive confirmation
$consent = Read-Host "You passed -Apply. Type 'YES' (all caps) to confirm you want to proceed and modify files"
if ($consent -ne 'YES') {
    Write-Host "Confirmation not received. Exiting without changes."
    exit 0
}

$pattern      = 'muscle'   # plain pattern (matches anywhere)
$replacement  = 'plzz'
$regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase

$filesChanged = 0
$filesSkipped = 0

foreach ($filePath in $files) {
    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
        Write-Host "File not found, skipping: $filePath" -ForegroundColor Red
        $filesSkipped++
        continue
    }

    # read file
    $content    = Get-Content -LiteralPath $filePath -Raw
    $matchCount = [regex]::Matches($content, $pattern, $regexOptions).Count

    if ($matchCount -eq 0) {
        Write-Host "No changes needed: $filePath (no matches found)" -ForegroundColor Yellow
        $filesSkipped++
        continue
    }

    # backup before modifying
    $timeStamp  = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $backupPath = Join-Path $backupRoot ((Split-Path $filePath -Leaf) + ".$timeStamp.bak")
    Copy-Item -LiteralPath $filePath -Destination $backupPath -Force
    Write-Host "Backup created: $backupPath" -ForegroundColor Cyan

    # replace everywhere
    $updatedContent = [regex]::Replace($content, $pattern, $replacement, $regexOptions)

    # write back (UTF8 default)
    Set-Content -LiteralPath $filePath -Value $updatedContent -Encoding UTF8
    Write-Host "Updated: $filePath ($matchCount replacements)" -ForegroundColor Green
    $filesChanged++
}

Write-Host ""

# colored summary
if ($filesChanged -gt 0) {
    Write-Host "Summary: Files changed: $filesChanged    Files skipped: $filesSkipped" -ForegroundColor Green
} else {
    Write-Host "Summary: Files changed: $filesChanged    Files skipped: $filesSkipped" -ForegroundColor Yellow
}
Write-Host "Backups are in: $backupRoot" -ForegroundColor Cyan
