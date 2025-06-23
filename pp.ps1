param (
    [Parameter(Mandatory = $true)]
    [string]$sourceSubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$sourceStorageAccount,

    [Parameter(Mandatory = $true)]
    [string]$sourceFileShare,

    [Parameter(Mandatory = $true)]
    [string]$sourceStorageKey,

    [Parameter(Mandatory = $true)]
    [string]$destinationSubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$destinationStorageAccount,

    [Parameter(Mandatory = $true)]
    [string]$destinationFileShare,

    [Parameter(Mandatory = $true)]
    [string]$destinationStorageKey
)

# Authenticate to Azure (handled by Automation Account)
Connect-AzAccount

# Set source subscription context
Set-AzContext -SubscriptionId $sourceSubscriptionId
Write-Output "Using source subscription: $sourceSubscriptionId"

# Create source context using storage key
$sourceContext = New-AzStorageContext -StorageAccountName $sourceStorageAccount -StorageAccountKey $sourceStorageKey

# Set destination subscription context
Set-AzContext -SubscriptionId $destinationSubscriptionId
Write-Output "Using destination subscription: $destinationSubscriptionId"

# Create destination context using storage key
$destinationContext = New-AzStorageContext -StorageAccountName $destinationStorageAccount -StorageAccountKey $destinationStorageKey

# Switch back to source subscription for listing files
Set-AzContext -SubscriptionId $sourceSubscriptionId

# List files in root of source file share
$files = Get-AzStorageFile -ShareName $sourceFileShare -Context $sourceContext -Path ""

foreach ($file in $files) {
    if ($file.GetType().Name -eq "CloudFile") {
        Write-Output "Copying file: $($file.Name)"

        Start-AzStorageFileCopy `
            -SrcShareName $sourceFileShare `
            -SrcFilePath $file.Name `
            -SrcContext $sourceContext `
            -DestShareName $destinationFileShare `
            -DestFilePath $file.Name `
            -DestContext $destinationContext
    }
}
