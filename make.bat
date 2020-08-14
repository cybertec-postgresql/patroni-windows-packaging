@ECHO off
SET MD=patroni-win-x64
SET ETCD_REF=https://github.com/etcd-io/etcd/releases/download/v3.3.22/etcd-v3.3.22-windows-amd64.zip
SET PATRONI_REF=https://github.com/zalando/patroni/archive/v1.6.5.zip
SET MICRO_REF=https://github.com/zyedidia/micro/releases/download/v2.0.6/micro-2.0.6-win64.zip
SET WINSW_REF=https://github.com/winsw/winsw/releases/download/v2.9.0/WinSW.NET461.exe

@ECHO --- Start bootstrapping ---

RMDIR /Q /S %MD% patroni > nul 2>&1
DEL %MD%.zip > nul 2>&1
MKDIR %MD%
COPY src\*.* %MD%\

@ECHO --- Update Python and PIP installation ---
CALL install-env.bat
MOVE python-install.exe %MD%\
@ECHO --- Python and PIP installation updated ---

@ECHO --- Download ETCD ---
curl %ETCD_REF% --location --output %TEMP%\etcd.zip
powershell -Command "Expand-Archive '%TEMP%\etcd.zip' '%CD%'"
MOVE etcd-* %MD%\etcd
@ECHO --- ETCD downloaded ---

@ECHO --- Download MICRO ---
curl %MICRO_REF% --location --output %TEMP%\micro.zip
powershell -Command "Expand-Archive '%TEMP%\micro.zip' '%CD%'"
MOVE micro-* %MD%\micro
@ECHO --- MICRO downloaded ---

@ECHO --- Download WINSW ---
MKDIR %MD%\service
curl %MICRO_REF% --location --output %MD%\service\patroni_service.exe
COPY %MD%\service\patroni_service.exe %MD%\service\etcd_service.exe /B
COPY %MD%\service\patroni_service.exe %MD%\service\vip_service.exe /B
@ECHO --- WINSW downloaded ---

@ECHO --- Download PATRONI ---
curl %PATRONI_REF% --location --output %TEMP%\patroni.zip
powershell -Command "Expand-Archive '%TEMP%\patroni.zip' '%CD%'"
MOVE patroni-* patroni
@ECHO --- PATRONI downloaded ---

@ECHO --- Download PATRONI packages ---
CD patroni
%PIP% download -r requirements.txt -d .patroni-packages
%PIP% download psycopg2-binary -d .patroni-packages
@ECHO --- PATRONI packages downloaded ---

CD ..
MOVE patroni %MD%\patroni

@ECHO --- Prepare archive ---
powershell -Command "Compress-Archive '%MD%' '%MD%.zip'"
@ECHO --- Archive compressed ---

@ECHO --- Creating windows installer ---
CALL make-installer.bat
@ECHO --- Installer generated successfully ---

@ECHO --- PACKAGING FINISHED ---

@PAUSE