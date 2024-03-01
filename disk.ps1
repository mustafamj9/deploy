Invoke-Command -ScriptBlock { 
    $disks = @(Get-Disk | Where-Object PartitionStyle -eq "RAW"); 
    for ($i = 0; $i -lt $disks.Count; $i++) { 
        $disknum = $disks[$i].Number; 
        $volume = Get-Disk $disknum | Initialize-Disk -PartitionStyle GPT -PassThru | 
                  New-Partition -AssignDriveLetter -UseMaximumSize; 
        Format-Volume -DriveLetter $volume.Driveletter -FileSystem ReFS -NewFileSystemLabel "Data $($disknum.ToString().PadLeft(2, "0"))" -Confirm:$false 
    } 
}
