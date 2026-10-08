$MD = "PES"

# Every binary download below is pinned to the SHA-256 of the exact artifact this
# packaging was built and tested against. Get-VerifiedFile refuses to continue on
# a mismatch. When bumping a *_REF below, recompute the matching *_SHA256 with:
#
#     (Get-FileHash <downloaded-file> -Algorithm SHA256).Hash
#
# and, where upstream publishes its own checksum file, cross-check against that
# rather than trusting the copy you just downloaded.
#
# The wheels fetched by Get-PatroniPackages are not covered; see the note there.

# aka.ms/vs/17/release always serves the current redistributable, so this one
# cannot be pinned. It is downloaded unverified by design.
$VCREDIST_REF = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$VCREDIST_SHA256 = ""

$ETCD_REF = "https://github.com/etcd-io/etcd/releases/download/v3.5.30/etcd-v3.5.30-windows-amd64.zip"
# cross-checked against https://github.com/etcd-io/etcd/releases/download/v3.5.30/SHA256SUMS
$ETCD_SHA256 = "B79BAFE87112C607CA95CB059EDBD31FAB7624371A8A0BE11EEF24BBAFB3F33F"

# NOTE: GitHub generates /archive/ tarballs on demand and has changed their
# byte-for-byte output in the past. If this hash ever fails on an unchanged tag,
# that is the likely cause -- verify the contents before updating it.
$PATRONI_REF = "https://github.com/patroni/patroni/archive/refs/tags/v4.1.2.zip"
$PATRONI_SHA256 = "AEDD472B54DE95BDBF592467B52B75E7D0A325FB6E08ACC2C8BFD34F6D63F2E2"

$MICRO_REF = "https://github.com/zyedidia/micro/releases/download/v2.0.15/micro-2.0.15-win64.zip"
$MICRO_SHA256 = "90635C53C11AA2A0D997F5E3ED43528877740725500207640B29551CEF18479B"

$WINSW_REF = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW.NET461.exe"
$WINSW_SHA256 = "B5066B7BBDFBA1293E5D15CDA3CAAEA88FBEAB35BD5B38C41C913D492AADFC4F"

$VIP_REF = "https://github.com/cybertec-postgresql/vip-manager/releases/download/v4.2.0/vip-manager_4.2.0_Windows_x86_64.zip"
$VIP_SHA256 = "97B5CA82EF7BBABA391A3C07CE30871801F03F3ED113B7585CECB60E814528A4"

$PGSQL_REF = "https://get.enterprisedb.com/postgresql/postgresql-18.3-1-windows-x64-binaries.zip"
$PGSQL_SHA256 = "4DA1A93CBC69E99936616D53C34466F79E4295FC56134CE4A395E88351213D60"

$PYTHON_REF = "https://www.python.org/ftp/python/3.14.4/python-3.14.4-amd64.exe"
$PYTHON_SHA256 = "B571567BD11EA98FD7A2CF85791D2C8557A63B1E04E9D1DAE665A275CAC87F1B"
# one should change python version in github action workflows when changed here

$SEVENZIP = "C:\Program Files\7-Zip\7z.exe"

function Invoke-SevenZip {
    param ([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & $SEVENZIP @Arguments
    # $ErrorActionPreference = "Stop" does NOT turn a non-zero native exit code into
    # a terminating error unless $PSNativeCommandUseErrorActionPreference is enabled,
    # and that is off by default. Without this check a failed extraction just carries
    # on, the source archive is deleted, and a truncated package gets shipped.
    if ($LASTEXITCODE -ne 0) {
        throw "7-Zip failed with exit code ${LASTEXITCODE}: $SEVENZIP $($Arguments -join ' ')"
    }
}

function Get-VerifiedFile {
    param (
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [string]$Sha256,
        [pscredential]$Credential,
        [int]$Retries = 3
    )

    $params = @{ Uri = $Uri; OutFile = $OutFile; TimeoutSec = 600 }
    if ($Credential) { $params.Credential = $Credential }

    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            Invoke-WebRequest @params
            break
        }
        catch {
            # Never leave a partial file behind for the hash check to trip over.
            Remove-Item -Force $OutFile -ErrorAction Ignore
            if ($attempt -eq $Retries) {
                throw "Download failed after $Retries attempts: $Uri`n$($_.Exception.Message)"
            }
            Write-Host "Attempt $attempt of $Retries failed, retrying: $Uri" -ForegroundColor Yellow
            Start-Sleep -Seconds (5 * $attempt)
        }
    }

    $name = Split-Path $OutFile -Leaf
    if ([string]::IsNullOrWhiteSpace($Sha256)) {
        Write-Host "WARNING: no SHA-256 pinned for $name - integrity NOT verified" -ForegroundColor Yellow
        return
    }

    $expected = $Sha256.Trim().ToUpperInvariant()
    $actual = (Get-FileHash -Path $OutFile -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $expected) {
        Remove-Item -Force $OutFile -ErrorAction Ignore
        throw ("SHA-256 mismatch for $Uri`n" +
            "  expected: $expected`n" +
            "  actual  : $actual`n" +
            "The download was discarded. If upstream legitimately re-published this " +
            "artifact, verify it and update the matching *_SHA256 in globals.ps1.")
    }
    Write-Host "SHA-256 verified: $name" -ForegroundColor DarkGray
}

function Expand-ZipFile {
    param (
        [string]$zipFilePath,
        [string]$destinationPath
    )
    if (Test-Path $SEVENZIP) {
        Invoke-SevenZip x "$zipFilePath" "-o$destinationPath"
    }
    else {
        Expand-Archive -Path "$zipFilePath" -DestinationPath "$destinationPath"
    }
    # Reached only when the extraction above succeeded.
    Remove-Item -Force "$zipFilePath" -ErrorAction Ignore
}

function Compress-ToZipFile {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )
    if (Test-Path $SEVENZIP) {
        Invoke-SevenZip a "$destinationPath" -y "$sourcePath"
    }
    else {
        Compress-Archive -Path "$sourcePath" -DestinationPath "$destinationPath"
    }
    # 7-Zip's "a" appends to an existing archive rather than replacing it, so a
    # stale file from an earlier run would satisfy a bare Test-Path. make.ps1
    # always runs clean.ps1 first, but check the result is real regardless.
    if (-Not (Test-Path $destinationPath)) {
        throw "Archive '$destinationPath' was not produced."
    }
    if ((Get-Item $destinationPath).Length -eq 0) {
        throw "Archive '$destinationPath' is empty."
    }
    if (Test-Path $SEVENZIP) {
        Invoke-SevenZip t "$destinationPath"
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
    Get-VerifiedFile -Uri $VCREDIST_REF -OutFile "$MD\vc_redist.x64.exe" -Sha256 $VCREDIST_SHA256
    Write-Host "`n--- VCREDIST downloaded ---" -ForegroundColor green
}

function Get-ETCD {
    Write-Host "`n--- Download ETCD ---" -ForegroundColor blue
    Get-VerifiedFile -Uri $ETCD_REF -OutFile "$env:TEMP\etcd.zip" -Sha256 $ETCD_SHA256
    Expand-ZipFile "$env:TEMP\etcd.zip" "$MD"
    Rename-Item "$MD\etcd-*" "etcd"
    Copy-Item "src\etcd.yaml" "$MD\etcd"
    Write-Host "`n--- ETCD downloaded ---" -ForegroundColor green
}

function Get-Micro {
    Write-Host "`n--- Download MICRO ---" -ForegroundColor blue
    Get-VerifiedFile -Uri $MICRO_REF -OutFile "$env:TEMP\micro.zip" -Sha256 $MICRO_SHA256
    Expand-ZipFile "$env:TEMP\micro.zip" "$MD"
    Rename-Item "$MD\micro-*" "micro"
    Write-Host "`n--- MICRO downloaded ---" -ForegroundColor green
}

function Get-VIPManager {
    Write-Host "`n--- Download VIP-MANAGER ---" -ForegroundColor blue
    Get-VerifiedFile -Uri $VIP_REF -OutFile "$env:TEMP\vip.zip" -Sha256 $VIP_SHA256
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
    Get-VerifiedFile -Uri $PGSQL_REF -OutFile "$env:TEMP\pgsql.zip" -Credential $PGSQL_CREDENTIAL -Sha256 $PGSQL_SHA256
    Expand-ZipFile "$env:TEMP\pgsql.zip" "$MD"
    Remove-Item -Recurse -Force "$MD\pgsql\pgAdmin 4", "$MD\pgsql\symbols" -ErrorAction Ignore
    Write-Host "`n--- POSTGRESQL downloaded ---" -ForegroundColor green
}

function Get-Patroni {
    Write-Host "`n--- Download PATRONI ---" -ForegroundColor blue
    Get-VerifiedFile -Uri $PATRONI_REF -OutFile "$env:TEMP\patroni.zip" -Sha256 $PATRONI_SHA256
    Expand-ZipFile "$env:TEMP\patroni.zip" "$MD"
    Rename-Item "$MD\patroni-*" "patroni"
    Remove-Item "$MD\patroni\postgres?.yml" -ErrorAction Ignore
    Copy-Item "src\patroni.yaml" "$MD\patroni"
    Write-Host "`n--- PATRONI downloaded ---" -ForegroundColor green
}

function Get-PythonVersion {
    # $PYTHON_REF looks like https://www.python.org/ftp/python/3.14.4/python-3.14.4-amd64.exe
    if ($PYTHON_REF -notmatch '/python/(\d+)\.(\d+)\.(\d+)/') {
        throw "Cannot determine the Python version from `$PYTHON_REF: $PYTHON_REF"
    }
    [PSCustomObject]@{
        Full       = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
        MajorMinor = "$($Matches[1]).$($Matches[2])"
        # All-users installs land in %ProgramFiles%\Python<major><minor>
        DirSuffix  = "$($Matches[1])$($Matches[2])"
    }
}

function Update-PythonAndPIP {
    Write-Host "`n--- Update Python and PIP installation ---" -ForegroundColor blue

    # Derive every version-dependent path from $PYTHON_REF so that bumping the
    # version in one place cannot leave a stale hard-coded directory behind.
    $Version = Get-PythonVersion
    $PYTHON = "python.exe"
    $PIP = "pip3.exe"

    if (-Not $env:RUNNER_TOOL_CACHE) {
        Write-Host "Running on a local machine builder" -ForegroundColor Yellow
        $InstallDir = Join-Path $env:ProgramFiles "Python$($Version.DirSuffix)"
        $PYTHON = Join-Path $InstallDir "python.exe"
        $PIP = Join-Path $InstallDir "Scripts\pip3.exe"
    }

    Write-Host "Loading the Python $($Version.Full) installation..." -ForegroundColor Blue
    Get-VerifiedFile -Uri $PYTHON_REF -OutFile "python-install.exe" -Sha256 $PYTHON_SHA256
    Start-Process -FilePath "python-install.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0" -Wait

    foreach ($exe in $PYTHON, $PIP) {
        if (-Not (Get-Command $exe -ErrorAction SilentlyContinue)) {
            throw "Expected '$exe' after installing Python $($Version.Full), but it was not found."
        }
    }

    & $PYTHON -m pip install --upgrade pip

    Write-Host "Python version is:" -ForegroundColor Green
    # 2>&1 because some Python builds report --version on stderr.
    $Reported = ((& $PYTHON --version 2>&1) | Out-String).Trim() -replace '^Python\s+', ''
    Write-Host $Reported

    # The interpreter that downloads the wheels must match the interpreter that
    # is shipped in the archive, otherwise the offline install gets wheels built
    # for the wrong ABI tag. On CI this is setup-python, configured separately.
    if ([string]::IsNullOrWhiteSpace($Reported)) {
        throw "Could not determine the version of '$PYTHON': '--version' produced no output."
    }
    if ($Reported -notlike "$($Version.MajorMinor).*") {
        throw ("Python $Reported is in use but `$PYTHON_REF pins $($Version.Full). " +
               "Update the python-version in .github/workflows/*.yml to match globals.ps1.")
    }
    if ($Reported -ne $Version.Full) {
        Write-Host "WARNING: running Python $Reported while `$PYTHON_REF pins $($Version.Full)" -ForegroundColor Yellow
    }

    Write-Host "PIP version is:" -ForegroundColor Green
    & $PIP --version

    $global:PYTHON = $PYTHON
    $global:PIP = $PIP

    Move-Item "python-install.exe" "$MD"
    Write-Host "`n--- Python and PIP installation updated ---" -ForegroundColor green
}

function Get-PatroniPackages {
    Write-Host "`n--- Download PATRONI packages ---" -ForegroundColor blue
    # These wheels ship in the archive but are not hash-pinned the way the
    # binaries above are: pip verifies each file against the sha256 the index
    # advertises, which is weaker than pinning it here. Pinning needs a
    # --require-hashes lockfile, because requirements.txt specifies ranges.
    Set-Location "$MD\patroni"
    & $PIP download -r requirements.txt -d .patroni-packages
    & $PIP download pip pip_install setuptools wheel cdiff psycopg psycopg-binary -d .patroni-packages
    Set-Location -Path "..\.."
    Write-Host "`n--- PATRONI packages downloaded ---" -ForegroundColor green
}

function Get-WinSW {
    Write-Host "`n--- Download WINSW ---" -ForegroundColor blue
    Get-VerifiedFile -Uri $WINSW_REF -OutFile "$MD\patroni\patroni_service.exe" -Sha256 $WINSW_SHA256
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
