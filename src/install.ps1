#Requires -Version 7.0
#Requires -RunAsAdministrator

Write-Host "--- Installing VC++ 2015-2019 redistributable ---" -ForegroundColor blue
Start-Process -FilePath .\vc_redist.x64.exe -ArgumentList "/install /quiet /norestart" -NoNewWindow -Wait
Write-Host "--- VC++ 2015-2019 redistributable installed ---`n" -ForegroundColor green

Write-Host "--- Installing Python runtime ---" -ForegroundColor blue
Start-Process -FilePath .\python-install.exe -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0" -NoNewWindow -Wait

# Update Path variable with installed Python
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# update pip and pipe output to stdout to avoid parallel execution
Set-Location 'patroni'
python.exe -m pip install --upgrade --no-index --find-links .patroni-packages pip | Out-Default
pip3.exe install --no-index --find-links .patroni-packages pip_install
pip3.exe install --no-index --find-links .patroni-packages setuptools
pip3.exe install --no-index --find-links .patroni-packages wheel
Write-Host "--- Python runtime installed ---`n" -ForegroundColor green

Write-Host "--- Installing Patroni packages ---" -ForegroundColor blue
pip3.exe install --no-index --find-links .patroni-packages -r requirements.txt
pip3.exe install --no-index --find-links .patroni-packages psycopg psycopg-binary
pip3.exe install --no-index --find-links .patroni-packages cdiff
Set-Location '..'
Write-Host "--- Patroni packages installed ---`n" -ForegroundColor green

$userName = "pes"
$out = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue
if($null -eq $out)
{
    Write-Host "--- Adding local user '$userName' for patroni service ---" -ForegroundColor blue
    $Password = ("a".."z")+("A".."Z") | Get-Random -Count 4
    $Password += "!","#","$","%","(",")","*","+",",","-","." | Get-Random -Count 2
    $Password += ("0".."9") | Get-Random -Count 2
    $Password = -join($Password)

    # The account gets the verbatim password ...
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    New-LocalUser $userName -Password $SecurePassword -Description "Patroni service account"

    # ... while the XML document gets an escaped copy. Applying Escape() before
    # New-LocalUser would store e.g. '&amp;' as the real password, which WinSW's XML
    # parser then reads back as '&' -- the two would never match.
    # String.Replace() is used instead of the -replace operator: -replace treats '$&',
    # '$1' etc. in the replacement as capture-group references and would corrupt any
    # password containing '$'.
    $ConfFile = Join-Path $PWD 'patroni\patroni_service.xml'
    $XmlPassword = [Security.SecurityElement]::Escape($Password)
    $Content = (Get-Content $ConfFile -Raw).Replace('12345', $XmlPassword)
    [System.IO.File]::WriteAllText($ConfFile, $Content, [System.Text.Encoding]::ASCII)

    Write-Host "--- Password for '$userName' is: $Password ---" -ForegroundColor yellow
    Write-Host "--- Note it down. It is also stored in 'patroni\patroni_service.xml' ---" -ForegroundColor yellow
    Write-Host "--- Patroni user '$userName' added ---`n" -ForegroundColor green
}
else
{
    Write-Host "--- WARNING: Patroni user '$userName' already exists! ---" -ForegroundColor red
    Write-Host "--- Please, set a correct password in 'patroni\patroni_service.xml'! ---`n" -ForegroundColor red
}

Write-Host "--- Installing Etcd service ---" -ForegroundColor blue
etcd\etcd_service.exe install | Out-Default
Write-Host "--- Etcd service sucessfully installed ---" -ForegroundColor green

Write-Host "--- Installing patroni service ---" -ForegroundColor blue
patroni\patroni_service.exe install | Out-Default
Write-Host "--- Patroni service sucessfully installed ---" -ForegroundColor green

Write-Host "--- Installing vip-manager service ---" -ForegroundColor blue
vip-manager\vip_service.exe install | Out-Default
Write-Host "--- vip-manager service sucessfully installed ---" -ForegroundColor green

$workDir = (Get-Location).tostring()
$python = (Get-Command python.exe).Source

# grant access to PES directory
Write-Host "--- Grant access to working directory ---" -ForegroundColor blue
icacls $workDir /q /c /t /grant $userName:F
Write-Host "--- Access to working directory granted ---" -ForegroundColor green

Write-Host "--- Enabling Etcd, Postgres and patroni (via python) to listen to incomming traffic ---" -ForegroundColor blue
netsh advfirewall firewall add rule name="etcd" dir=in action=allow program="$workDir\etcd\etcd.exe" enable=yes
netsh advfirewall firewall add rule name="postgresql" dir=in action=allow program="$workDir\pgsql\bin\postgres.exe" enable=yes
netsh advfirewall firewall add rule name="python" dir=in action=allow program="$python" enable=yes
Write-Host "--- Firewall rules sucessfully installed ---" -ForegroundColor green

Write-Host "--- Installation sucessfully finished ---" -ForegroundColor green
