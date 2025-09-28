New-Item -ItemType Directory -Path "C:\Tools\aztfexport" -Force

Copy-Item "C:\Program Files\aztfexport\aztfexport.exe" "C:\Tools\aztfexport\"


$folder = "C:\Tools\aztfexport"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";" + $folder, "User")

aztfexport --version


New-Item -ItemType Directory -Path "E:\Terraform\backup-rg" -Force
cd "E:\Terraform\backup-rg"

az login
az account set --subscription ""



aztfexport resource-group resource_group-App-NP --path "E:\Az Migration"
