# Define your checks (host + port)
$checks = @(
    @{ Name = "PostgreSQL Local"; ComputerName = "localhost"; Port = 5432 },
    @{ Name = "SQL Server Local"; ComputerName = "localhost"; Port = 1433 },
    @{ Name = "API Service";      ComputerName = "localhost"; Port = 3001 },
    @{ Name = "Remote Server 1";  ComputerName = "192.168.1.50"; Port = 5432 },
    @{ Name = "Remote Server 2";  ComputerName = "192.168.1.60"; Port = 1433 }
)

# Run Test-NetConnection for each check
foreach ($check in $checks) {
    Write-Host "==============================="
    Write-Host "Testing $($check.Name) on $($check.ComputerName):$($check.Port)..."
    Write-Host "==============================="

    # Run tnc and capture result
    $result = Test-NetConnection -ComputerName $check.ComputerName -Port $check.Port

    # Show the full details
    $result

    # Add summary
    if ($result.TcpTestSucceeded) {
        Write-Host "✅ $($check.Name) - Connection successful" -ForegroundColor Green
    } else {
        Write-Host "❌ $($check.Name) - Connection failed" -ForegroundColor Red
    }
    Write-Host ""
}
