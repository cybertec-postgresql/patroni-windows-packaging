$MD = "PES"
$VCREDIST_REF = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$ETCD_REF = "https://github.com/etcd-io/etcd/releases/download/v3.5.21/etcd-v3.5.21-windows-amd64.zip"
$PATRONI_REF = "https://github.com/patroni/patroni/archive/refs/tags/v4.0.6.zip"
$MICRO_REF = "https://github.com/zyedidia/micro/releases/download/v2.0.14/micro-2.0.14-win64.zip"
$WINSW_REF = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW.NET461.exe"
$VIP_REF = "https://github.com/cybertec-postgresql/vip-manager/releases/download/v4.0.0/vip-manager_4.0.0_Windows_x86_64.zip"
$PGSQL_REF = "https://get.enterprisedb.com/postgresql/postgresql-17.5-1-windows-x64-binaries.zip"
$PYTHON_REF = "https://www.python.org/ftp/python/3.13.5/python-3.13.5-amd64.exe"
# one should change python version in github action workflows when changed here

$SEVENZIP = "C:\Program Files\7-Zip\7z.exe"

function Expand-ZipFile {
    param (
        [string]$zipFilePath,
        [string]$destinationPath
    )
    if (Test-Path $SEVENZIP) {
        & $SEVENZIP x "$zipFilePath" -o"$destinationPath"
        Start-Sleep -Seconds 5
    }
    else {
        Expand-Archive -Path "$zipFilePath" -DestinationPath "$destinationPath"
    }
    Remove-Item -Force "$zipFilePath" -ErrorAction Ignore
}

function Compress-ToZipFile {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )
    if (Test-Path $SEVENZIP) {
        & $SEVENZIP a "$destinationPath" -y "$sourcePath"
    }
    else {
        Compress-Archive -Path "$sourcePath" -DestinationPath "$destinationPath"
    }
}

function Start-Bootstrapping {
    Write-Host "`n--- Start bootstrapping ---" -ForegroundColor blue
    & ./clean.ps1
    New-Item -ItemType Directory -Path $MD
    Copy-Item "src\*.bat" $MD
    Copy-Item "src\*.ps1" $MD
    Copy-Item "doc" "$MD\doc" -Recurse
    Write-Host "`n--- End bootstrapping ---" -ForegroundColor green
}

function Get-VCRedist {
    Write-Host "`n--- Download VCREDIST ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $VCREDIST_REF -OutFile "$MD\vc_redist.x64.exe"
    Write-Host "`n--- VCREDIST downloaded ---" -ForegroundColor green
}

function Get-ETCD {
    Write-Host "`n--- Download ETCD ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $ETCD_REF -OutFile "$env:TEMP\etcd.zip"
    Expand-ZipFile "$env:TEMP\etcd.zip" "$MD"
    Rename-Item "$MD\etcd-*" "etcd"
    Copy-Item "src\etcd.yaml" "$MD\etcd"
    Write-Host "`n--- ETCD downloaded ---" -ForegroundColor green
}

function Get-Micro {
    Write-Host "`n--- Download MICRO ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $MICRO_REF -OutFile "$env:TEMP\micro.zip"
    Expand-ZipFile "$env:TEMP\micro.zip" "$MD"
    Rename-Item "$MD\micro-*" "micro"
    Write-Host "`n--- MICRO downloaded ---" -ForegroundColor green
}

function Get-VIPManager {
    Write-Host "`n--- Download VIP-MANAGER ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $VIP_REF -OutFile "$env:TEMP\vip.zip"
    Expand-ZipFile "$env:TEMP\vip.zip" "$MD"
    Rename-Item "$MD\vip-manager*" "vip-manager"
    Remove-Item "$MD\vip-manager\*.yml" -ErrorAction Ignore
    Copy-Item "src\vip.yaml" "$MD\vip-manager"
    Write-Host "`n--- VIP-MANAGER downloaded ---" -ForegroundColor green
}

function Get-PostgreSQL {
    Write-Host "`n--- Download POSTGRESQL ---" -ForegroundColor blue
    # Use prompt for credentials if auth is required
    # if (-not $PGSQL_CREDENTIAL) {
    #     $global:PGSQL_CREDENTIAL = Get-Credential -Message "Enter credentials for PostgreSQL download"
    # }
    Invoke-WebRequest -Uri $PGSQL_REF -OutFile "$env:TEMP\pgsql.zip" -Credential $PGSQL_CREDENTIAL
    Expand-ZipFile "$env:TEMP\pgsql.zip" "$MD"
    Remove-Item -Recurse -Force "$MD\pgsql\pgAdmin 4", "$MD\pgsql\symbols" -ErrorAction Ignore
    Write-Host "`n--- POSTGRESQL downloaded ---" -ForegroundColor green
}

function Get-Patroni {
    Write-Host "`n--- Download PATRONI ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $PATRONI_REF -OutFile "$env:TEMP\patroni.zip"
    Expand-ZipFile "$env:TEMP\patroni.zip" "$MD"
    Rename-Item "$MD\patroni-*" "patroni"
    Remove-Item "$MD\patroni\postgres?.yml" -ErrorAction Ignore
    Copy-Item "src\patroni.yaml" "$MD\patroni"
    Write-Host "`n--- PATRONI downloaded ---" -ForegroundColor green
}

function Update-PythonAndPIP {
    Write-Host "`n--- Update Python and PIP installation ---" -ForegroundColor blue
    $PYTHON = "python.exe"
    $PIP = "pip3.exe"
    
    if (-Not $env:RUNNER_TOOL_CACHE) {
        Write-Host "Running on a local machine builder" -ForegroundColor Yellow
        $PYTHON = "$env:ProgramFiles\Python313\python.exe"
        $PIP = "$env:ProgramFiles\Python313\Scripts\pip3.exe"
    }
    
    Write-Host "Loading the Python installation..." -ForegroundColor Blue
    Invoke-WebRequest -Uri $PYTHON_REF -OutFile "python-install.exe"
    Start-Process -FilePath "python-install.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0" -Wait
    
    & $PYTHON -m pip install --upgrade pip
    
    Write-Host "Python version is:" -ForegroundColor Green
    & $PYTHON --version
    
    Write-Host "PIP version is:" -ForegroundColor Green
    & $PIP --version
    
    $global:PYTHON = $PYTHON
    $global:PIP = $PIP
    
    Move-Item "python-install.exe" "$MD"
    Write-Host "`n--- Python and PIP installation updated ---" -ForegroundColor green
}

function Get-PatroniPackages {
    Write-Host "`n--- Download PATRONI packages ---" -ForegroundColor blue
    Set-Location "$MD\patroni"
    & $PIP download -r requirements.txt -d .patroni-packages
    & $PIP download pip pip_install setuptools wheel cdiff psycopg psycopg-binary -d .patroni-packages
    Set-Location -Path "..\.."
    Write-Host "`n--- PATRONI packages downloaded ---" -ForegroundColor green
}

function Get-WinSW {
    Write-Host "`n--- Download WINSW ---" -ForegroundColor blue
    Invoke-WebRequest -Uri $WINSW_REF -OutFile "$MD\patroni\patroni_service.exe"
    Copy-Item "src\patroni_service.xml" "$MD\patroni"
    Copy-Item "$MD\patroni\patroni_service.exe" "$MD\etcd\etcd_service.exe" -Force
    Copy-Item "src\etcd_service.xml" "$MD\etcd"
    Copy-Item "$MD\patroni\patroni_service.exe" "$MD\vip-manager\vip_service.exe" -Force
    Copy-Item "src\vip_service.xml" "$MD\vip-manager"
    Write-Host "`n--- WINSW downloaded ---" -ForegroundColor green
}

function Export-Assets {
    Write-Host "`n--- Prepare archive ---" -ForegroundColor blue
    Compress-ToZipFile "$MD" "$MD.zip" 
    Write-Host "`n--- Archive compressed ---" -ForegroundColor green
}
