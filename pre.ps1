<#
    AzCopy: Copy ONLY the contents of a subdirectory from one Azure Files share to another
    - Copies contents of <SRC_SUBDIR> into <DST_SUBDIR> (no extra parent folder)
    - Uses SAS URLs. Do NOT commit real SAS tokens.
    - Requires AzCopy v10+

    HOW TO USE:
      1) Replace placeholders <> below with your values.
      2) Run in PowerShell.
      3) Ensure the SAS tokens have:
         - Service: File (ss includes 'f')
         - Resource types: Service, Container, Object (srt = 'sco')
         - Permissions: source needs at least read+list; destination needs create+write+list (+update/delete if overwriting)
#>

# ---------------- CONFIG ----------------
# Full path to azcopy.exe
# to find out the path Get-ChildItem -Path "C:\Users\musta\Downloads" -Recurse -Filter "azcopy.exe"
$azCopyExe = "<AZCOPY_EXE_PATH>"  # e.g. C:\Tools\AzCopy\azcopy.exe

# SAS URL to the SOURCE share (NO subdir appended here)
# EXAMPLE SHAPE: https://<SRC_ACCOUNT>.file.core.windows.net/<SHARE_NAME>?<SAS>
$sourceUrl = "https://<SRC_ACCOUNT>.file.core.windows.net/<SRC_SHARE>?<SRC_SAS>"

# SAS URL to the DESTINATION share (NO subdir appended here)
# EXAMPLE SHAPE: https://<DST_ACCOUNT>.file.core.windows.net/<SHARE_NAME>?<DST_SAS>
$destUrl   = "https://<DST_ACCOUNT>.file.core.windows.net/<DST_SHARE>?<DST_SAS>"

# Subdirectory to copy (same relative path on both sides)
# IMPORTANT: This is the directory whose CONTENTS will be copied.
$srcSubDir = "<SRC_SUBDIR_RELATIVE_PATH>"  # e.g.
$dstSubDir = "<DST_SUBDIR_RELATIVE_PATH>"  # e.g.

# ---------------- HELPERS ----------------
# Inserts the relative path BEFORE the ?SAS. Optionally adds:
#   - "/*" to copy only contents of a folder
#   - "/"  to force destination to be treated as a directory
function Build-Url {
    param(
        [Parameter(Mandatory)][string]$baseSasUrl,
        [Parameter(Mandatory)][string]$relPath,
        [string]$suffix = ""
    )
    $parts = $baseSasUrl -split '\?', 2
    $base  = $parts[0].TrimEnd('/')
    $sas   = if ($parts.Count -gt 1) { '?' + $parts[1] } else { '' }
    return "$base/$relPath$suffix$sas"
}

# ---------------- BUILD FINAL URLS ----------------
# Source = contents only => add "/*" so we copy files/folders inside the subdir, not the subdir itself
$srcUrlContents = Build-Url -baseSasUrl $sourceUrl -relPath $srcSubDir -suffix "/*"

# Destination = target directory => add trailing "/" so AzCopy treats it as a directory
$dstUrlDir      = Build-Url -baseSasUrl $destUrl   -relPath $dstSubDir -suffix "/"

# ---------------- ENSURE DESTINATION FOLDER EXISTS (idempotent) ----------------
# Creates the destination folder chain if missing. Safe to run repeatedly.
& $azCopyExe make $dstUrlDir | Out-Null

# ---------------- COPY (INCREMENTAL) ----------------
# Copies all files and subfolders from source subdir CONTENTS into the destination directory.
# Does NOT delete anything at destination.
& $azCopyExe copy $srcUrlContents $dstUrlDir --recursive --overwrite=ifSourceNewer

# ---------------- NOTES ----------------
# - If you want to *mirror* (delete extras on destination), use `azcopy sync` instead of copy:
#     & $azCopyExe sync (Build-Url $sourceUrl $srcSubDir "/") (Build-Url $destUrl $dstSubDir "/") --recursive --delete-destination=true
#   (Make sure the destination parent path exists first; and consider running with --dry-run.)
# - If you need to preserve SMB ACLs/attributes (supported on both accounts), add:
#     --preserve-smb-permissions=true --preserve-smb-info=true
# - Keep SAS tokens short-lived and NEVER commit real SAS to source control.
