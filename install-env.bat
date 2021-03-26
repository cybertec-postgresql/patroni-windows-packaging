@ECHO off

SET PYTHON_REF=https://www.python.org/ftp/python/3.9.2/python-3.9.2-amd64.exe
SET PYTHON=python.exe
SET PIP=pip3.exe

curl %PYTHON_REF% --output python-install.exe
python-install.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0
%PYTHON% -m pip install --upgrade pip