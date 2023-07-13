@ECHO off
SET MD=PES
SET ETCD_REF=https://github.com/etcd-io/etcd/releases/download/v3.5.7/etcd-v3.5.7-windows-amd64.zip
SET PATRONI_REF=https://github.com/zalando/patroni/archive/refs/tags/v3.0.3.zip
SET MICRO_REF=https://github.com/zyedidia/micro/releases/download/v2.0.11/micro-2.0.11-win64.zip
SET WINSW_REF=https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW.NET461.exe
SET VIP_REF=https://github.com/cybertec-postgresql/vip-manager/releases/download/v2.1.0/vip-manager_2.1.0_Windows_x86_64.zip
SET PGSQL_REF=https://get.enterprisedb.com/postgresql/postgresql-15.1-1-windows-x64-binaries.zip
SET PES_REF=https://github.com/cybertec-postgresql/PES/releases/download/v0.2/pes.zip

SET SEVENZIP="C:\Program Files\7-Zip\7z.exe"

@ECHO --- Start bootstrapping ---
RMDIR /Q /S %MD% patroni > nul 2>&1
DEL %MD%.zip > nul 2>&1
DEL %TEMP%\etcd.zip > nul 2>&1
DEL %TEMP%\pes.zip > nul 2>&1
DEL %TEMP%\micro.zip > nul 2>&1
DEL %TEMP%\vip.zip > nul 2>&1
DEL %TEMP%\pgsql.zip > nul 2>&1
DEL %TEMP%\patroni.zip > nul 2>&1
DEL Patroni-Env-Setup.exe > nul 2>&1
MKDIR %MD% || EXIT /B
COPY src\*.bat %MD%\ || EXIT /B
COPY src\*.ps1 %MD%\ || EXIT /B
XCOPY doc %MD%\doc\ /E || EXIT /B
@ECHO --- End bootstrapping ---


@ECHO --- Download ETCD ---
curl %ETCD_REF% --location --output %TEMP%\etcd.zip || EXIT /B
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\etcd.zip" -y -o"%CD%" || EXIT /B
) else (
    powershell -Command "Expand-Archive '%TEMP%\etcd.zip' '%CD%'" || EXIT /B
)
REM timeouts are used here to give 7-Zip some time to release output folder and prevent "Access denied" error
TIMEOUT 5 
MOVE etcd-* %MD%\etcd || EXIT /B
COPY src\etcd.yaml %MD%\etcd\ || EXIT /B
DEL %TEMP%\etcd.zip || EXIT /B
@ECHO --- ETCD downloaded ---



@ECHO --- Download PES GUI ---
curl %PES_REF% --location --output %TEMP%\pes.zip || EXIT /B
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\pes.zip" -y -o"%MD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\pes.zip' '%MD%'"
)
DEL %TEMP%\pes.zip || EXIT /B
@ECHO --- PES GUI downloaded ---

@ECHO --- Download MICRO ---
curl %MICRO_REF% --location --output %TEMP%\micro.zip || EXIT /B
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\micro.zip" -y -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\micro.zip' '%CD%'"
)
TIMEOUT 5
MOVE micro-* %MD%\micro || EXIT /B
DEL %TEMP%\micro.zip || EXIT /B
@ECHO --- MICRO downloaded ---

@ECHO --- Download VIP-MANAGER ---
curl %VIP_REF% --location --output %TEMP%\vip.zip || EXIT /B
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\vip.zip" -y -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\vip.zip' '%CD%'"
)
TIMEOUT 5
MOVE vip-manager* %MD%\vip-manager || EXIT /B
DEL %MD%\vip-manager\*.yml || EXIT /B
COPY src\vip.yaml %MD%\vip-manager\ || EXIT /B
DEL %TEMP%\vip.zip || EXIT /B
@ECHO --- VIP-MANAGER downloaded ---



@ECHO --- Download POSTGRESQL ---
curl %PGSQL_REF% --location --output %TEMP%\pgsql.zip || EXIT /B
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\pgsql.zip" -y -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\pgsql.zip' '%CD%'"
)
TIMEOUT 5
MOVE pgsql* %MD%\pgsql || EXIT /B
RMDIR /Q /S "%MD%\pgsql\pgAdmin 4" "%MD%\pgsql\symbols" || EXIT /B
DEL %TEMP%\pgsql.zip || EXIT /B
@ECHO --- POSTGRESQL downloaded ---



@ECHO --- Download PATRONI ---
curl %PATRONI_REF% --location --output %TEMP%\patroni.zip || EXIT /B
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\patroni.zip" -y -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\patroni.zip' '%CD%'"
)
TIMEOUT 5 
MOVE patroni-* %MD%\patroni || EXIT /B
DEL %MD%\patroni\postgres?.yml || EXIT /B
COPY src\patroni.yaml %MD%\patroni\ || EXIT /B
DEL %TEMP%\patroni.zip || EXIT /B
@ECHO --- PATRONI downloaded ---



@ECHO --- Update Python and PIP installation ---
CALL install-env.bat || EXIT /B
MOVE python-install.exe %MD%\ || EXIT /B
@ECHO --- Python and PIP installation updated ---



@ECHO --- Download PATRONI packages ---
CD %MD%\patroni
%PIP% download -r requirements.txt -d .patroni-packages
%PIP% download psycopg2-binary -d .patroni-packages
CD ..\..
@ECHO --- PATRONI packages downloaded ---



@ECHO --- Download WINSW ---
curl %WINSW_REF% --location --output %MD%\patroni\patroni_service.exe || EXIT /B
COPY src\patroni_service.xml %MD%\patroni\ || EXIT /B
COPY %MD%\patroni\patroni_service.exe %MD%\etcd\etcd_service.exe /B || EXIT /B
COPY src\etcd_service.xml %MD%\etcd\ || EXIT /B
COPY %MD%\patroni\patroni_service.exe %MD%\vip-manager\vip_service.exe /B || EXIT /B
COPY src\vip_service.xml %MD%\vip-manager\ || EXIT /B
@ECHO --- WINSW downloaded ---



@ECHO --- Creating windows installer ---
CALL make-installer.bat || EXIT /B
@ECHO --- Installer generated successfully ---



@ECHO --- Prepare archive ---
if exist %SEVENZIP% (
    %SEVENZIP% a "%MD%.zip" -y "%MD%"
) else (
    powershell -Command "Compress-Archive '%MD%' '%MD%.zip'"
)
@ECHO --- Archive compressed ---

@ECHO --- PACKAGING FINISHED ---