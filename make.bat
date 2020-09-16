@ECHO off
SET MD=PES
SET ETCD_REF=https://github.com/etcd-io/etcd/releases/download/v3.3.25/etcd-v3.3.22-windows-amd64.zip
SET PATRONI_REF=https://github.com/zalando/patroni/archive/v2.0.0.zip
SET MICRO_REF=https://github.com/zyedidia/micro/releases/download/v2.0.7/micro-2.0.7-win64.zip
SET WINSW_REF=https://github.com/winsw/winsw/releases/download/v2.10.2/WinSW.NET461.exe
SET VIP_REF=https://github.com/cybertec-postgresql/vip-manager/releases/download/v1.0-beta/vip-manager.zip
SET PGSQL_REF=https://get.enterprisedb.com/postgresql/postgresql-12.4-1-windows-x64-binaries.zip
SET SEVENZIP="C:\Program Files\7-Zip\7z.exe"

@ECHO --- Start bootstrapping ---

RMDIR /Q /S %MD% patroni > nul 2>&1
DEL %MD%.zip > nul 2>&1
DEL Patroni-Env-Setup.exe > nul 2>&1
MKDIR %MD%
COPY src\*.bat %MD%\
COPY src\*.ps1 %MD%\
XCOPY doc %MD%\doc\ /E

@ECHO --- Update Python and PIP installation ---
CALL install-env.bat
MOVE python-install.exe %MD%\
@ECHO --- Python and PIP installation updated ---

@ECHO --- Download ETCD ---
curl %ETCD_REF% --location --output %TEMP%\etcd.zip
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\etcd.zip" -y -mmt -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\etcd.zip' '%CD%'"
)
MOVE etcd-* %MD%\etcd
@ECHO --- ETCD downloaded ---

@ECHO --- Download MICRO ---
curl %MICRO_REF% --location --output %TEMP%\micro.zip
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\micro.zip" -y -mmt -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\micro.zip' '%CD%'"
)
MOVE micro-* %MD%\micro
@ECHO --- MICRO downloaded ---

@ECHO --- Download VIP-MANAGER ---
curl %VIP_REF% --location --output %TEMP%\vip.zip
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\vip.zip" -y -mmt -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\vip.zip' '%CD%'"
)
MOVE vip-manager* %MD%\vip-manager
@ECHO --- VIP-MANAGER downloaded ---

@ECHO --- Download POSTGRESQL ---
curl %PGSQL_REF% --location --output %TEMP%\pgsql.zip
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\pgsql.zip" -y -mmt -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\pgsql.zip' '%CD%'"
)
MOVE pgsql* %MD%\pgsql
RMDIR /Q /S "%MD%\pgsql\pgAdmin 4" "%MD%\pgsql\symbols"
@ECHO --- POSTGRESQL downloaded ---

@ECHO --- Download PATRONI ---
curl %PATRONI_REF% --location --output %TEMP%\patroni.zip
if exist %SEVENZIP% (
    %SEVENZIP% x "%TEMP%\patroni.zip" -y -mmt -o"%CD%"
) else (
    powershell -Command "Expand-Archive '%TEMP%\patroni.zip' '%CD%'"
)
MOVE patroni-* %MD%\patroni
DEL %MD%\patroni\postgres?.yml
COPY src\patroni.yml %MD%\patroni\
@ECHO --- PATRONI downloaded ---

@ECHO --- Download PATRONI packages ---
CD %MD%\patroni
%PIP% download -r requirements.txt -d .patroni-packages
%PIP% download psycopg2-binary -d .patroni-packages
CD ..\..
@ECHO --- PATRONI packages downloaded ---

@ECHO --- Download WINSW ---
curl %WINSW_REF% --location --output %MD%\patroni\patroni_service.exe
COPY src\patroni_service.xml %MD%\patroni\
COPY %MD%\patroni\patroni_service.exe %MD%\etcd\etcd_service.exe /B
COPY src\etcd_service.xml %MD%\etcd\
COPY %MD%\patroni\patroni_service.exe %MD%\vip-manager\vip_service.exe /B
COPY src\vip_service.xml %MD%\vip-manager\
@ECHO --- WINSW downloaded ---

@ECHO --- Prepare archive ---
if exist %SEVENZIP% (
    %SEVENZIP% a "%MD%.zip" -y -mmt "%MD%"
) else (
    powershell -Command "Compress-Archive '%MD%' '%MD%.zip'"
)
@ECHO --- Archive compressed ---

@ECHO --- Creating windows installer ---
CALL make-installer.bat
@ECHO --- Installer generated successfully ---

@ECHO --- PACKAGING FINISHED ---

@PAUSE