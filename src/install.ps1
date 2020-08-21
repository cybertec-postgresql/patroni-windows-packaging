Write-Host "--- Installing Python runtime ---" -ForegroundColor blue
.\python-install.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0
python.exe -m pip install --upgrade pip
Write-Host "--- Python runtime installed ---`n" -ForegroundColor green

# Update Path variable with installed Python
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "--- Installing Patroni packages ---" -ForegroundColor blue
Set-Location 'patroni'
pip3.exe install --no-index --find-links .patroni-packages -r requirements.txt
pip3.exe install --no-index --find-links .patroni-packages psycopg2-binary
Set-Location '..'
Write-Host "--- Patroni packages installed ---`n" -ForegroundColor green

Write-Host "--- Adding local user 'pes' for patroni service ---" -ForegroundColor blue
$Password = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
New-LocalUser "pes" -Password $SecurePassword -Description "Patroni service account"
$ConfFile = 'patroni\patroni_service.xml'
(Get-Content $ConfFile) -replace '12345', $Password | Out-File -encoding ASCII $ConfFile
Write-Host "User password: $Password"
Write-Host "--- Patroni user added ---`n" -ForegroundColor green

Write-Host "--- Installation sucessfully finished ---" -ForegroundColor green