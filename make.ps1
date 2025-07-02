# Stop execution on any error
$ErrorActionPreference = "Stop"

# Set the environment variables
. .\env.ps1

Start-Bootstrapping
Get-VCRedist
Get-ETCD
Get-Micro
Get-VIPManager
Get-PostgreSQL
Get-Patroni
Update-PythonAndPIP
Get-PatroniPackages
Get-WinSW
Export-Assets
Write-Host "`n--- PACKAGING FINISHED ---" -ForegroundColor green
