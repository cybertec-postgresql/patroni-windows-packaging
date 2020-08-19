@ECHO off
SET MD=patroni-win-x64
SET ETCD_REF=https://github.com/etcd-io/etcd/releases/download/v3.3.22/etcd-v3.3.22-windows-amd64.zip
SET PATRONI_REF=https://github.com/zalando/patroni/archive/v1.6.5.zip
SET MICRO_REF=https://github.com/zyedidia/micro/releases/download/v2.0.6/micro-2.0.6-win64.zip
SET WINSW_REF=https://github.com/winsw/winsw/releases/download/v2.9.0/WinSW.NET461.exe
SET VIP_REF=https://github.com/cybertec-postgresql/vip-manager/releases/download/v1.0-beta/vip-manager.zip

@ECHO --- Start bootstrapping ---

RMDIR /Q /S %MD% patroni > nul 2>&1
DEL %MD%.zip > nul 2>&1
MKDIR %MD%
COPY src\*.bat %MD%\

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

@ECHO --- Download VIP-MANAGER ---
curl %VIP_REF% --location --output %TEMP%\vip.zip
powershell -Command "Expand-Archive '%TEMP%\vip.zip' '%CD%'"
MOVE vip-manager* %MD%\vip-manager
@ECHO --- VIP-MANAGER downloaded ---

@ECHO --- Download WINSW ---
curl %WINSW_REF% --location --output %MD%\patroni\patroni_service.exe
COPY src\patroni_service.xml %MD%\etcd\
COPY %MD%\patroni\patroni_service.exe %MD%\etcd\etcd_service.exe /B
COPY src\etcd_service.xml %MD%\etcd\
COPY %MD%\patroni\patroni_service.exe %MD%\vip-manager\vip_service.exe /B
COPY src\vip_service.xml %MD%\vip-manager\
@ECHO --- WINSW downloaded ---

@ECHO --- Download PATRONI ---
curl %PATRONI_REF% --location --output %TEMP%\patroni.zip
powershell -Command "Expand-Archive '%TEMP%\patroni.zip' '%CD%'"
MOVE patroni-* %MD%\patroni
DEL %MD%\patroni\postgres?.yml
MOVE %MD%\patroni.yml %MD%\patroni\
@ECHO --- PATRONI downloaded ---

@ECHO --- Download PATRONI packages ---
CD %MD%\patroni
%PIP% download -r requirements.txt -d .patroni-packages
%PIP% download psycopg2-binary -d .patroni-packages
CD ..\..
@ECHO --- PATRONI packages downloaded ---

@ECHO --- Prepare archive ---
powershell -Command "Compress-Archive '%MD%' '%MD%.zip'"
@ECHO --- Archive compressed ---

@ECHO --- Creating windows installer ---
CALL make-installer.bat
@ECHO --- Installer generated successfully ---

@ECHO --- PACKAGING FINISHED ---

@PAUSE