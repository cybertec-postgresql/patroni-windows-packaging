#Requires -Version 7.0
#Requires -RunAsAdministrator

Write-Host "--- Uninstalling Etcd service ---" -ForegroundColor blue
etcd\etcd_service.exe uninstall | Out-Default
Write-Host "--- Etcd service sucessfully uninstalled ---" -ForegroundColor green

Write-Host "--- Uninstalling patroni service ---" -ForegroundColor blue
patroni\patroni_service.exe uninstall | Out-Default
Write-Host "--- Patroni service sucessfully uninstalled ---" -ForegroundColor green

Write-Host "--- Uninstalling vip-manager service ---" -ForegroundColor blue
vip-manager\vip_service.exe uninstall | Out-Default
Write-Host "--- vip-manager service sucessfully uninstalled ---" -ForegroundColor green

Write-Host "--- Disabling Etcd, Postgres and patroni firewall rules ---" -ForegroundColor blue
netsh advfirewall firewall delete rule name="etcd"
netsh advfirewall firewall delete rule name="postgresql"
netsh advfirewall firewall delete rule name="python"
Write-Host "--- Firewall rules sucessfully deleted ---" -ForegroundColor green

Write-Host "--- Uninstallation sucessfully finished ---" -ForegroundColor green