Write-Host "--- Installing Python runtime ---" -ForegroundColor blue
Start-Process -FilePath .\python-install.exe -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0" -NoNewWindow -Wait
# update pip and pipe output to stdout to avoid parallel execution
python.exe -m pip install --upgrade pip | Out-Default
Write-Host "--- Python runtime installed ---`n" -ForegroundColor green

# Update Path variable with installed Python
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "--- Installing Patroni packages ---" -ForegroundColor blue
Set-Location 'patroni'
pip3.exe install --no-index --find-links .patroni-packages -r requirements.txt
pip3.exe install --no-index --find-links .patroni-packages psycopg2-binary
Set-Location '..'
Write-Host "--- Patroni packages installed ---`n" -ForegroundColor green

$userName = "pes"
$out = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue
if($out -eq $null)
{
    Write-Host "--- Adding local user '$userName' for patroni service ---" -ForegroundColor blue
    $Password = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    New-LocalUser $userName -Password $SecurePassword -Description "Patroni service account"
    $ConfFile = 'patroni\patroni_service.xml'
    (Get-Content $ConfFile) -replace '12345', $Password | Out-File -encoding ASCII $ConfFile
    Write-Host "--- Patroni user '$userName' added ---`n" -ForegroundColor green
}
else
{
    Write-Host "--- Patroni user '$userName' already exists ---`n" -ForegroundColor green
}

Write-Host "--- Installing Etcd service ---" -ForegroundColor blue
etcd\etcd_service.exe install | Out-Default
Write-Host "--- Etcd service sucessfully installed ---" -ForegroundColor green

Write-Host "--- Installing patroni service ---" -ForegroundColor blue
patroni\patroni_service.exe install | Out-Default
Write-Host "--- Patroni service sucessfully installed ---" -ForegroundColor green

Write-Host "--- Installing vip-manager service ---" -ForegroundColor blue
vip-manager\vip-manager_service.exe install | Out-Default
Write-Host "--- vip-manager service sucessfully installed ---" -ForegroundColor green

Write-Host "--- Installation sucessfully finished ---" -ForegroundColor green