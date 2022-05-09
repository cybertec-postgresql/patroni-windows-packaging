@ECHO off

SET "PYTHON_REF=https://www.python.org/ftp/python/3.10.4/python-3.10.4-amd64.exe"
SET PYTHON="%ProgramFiles%\Python310\python.exe"
SET PIP="%ProgramFiles%\Python310\Scripts\pip3.exe"

curl %PYTHON_REF% --output python-install.exe
python-install.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0
%PYTHON% -m pip install --upgrade pip

echo Python version is:
%PYTHON% --version || python --version

echo PIP version is:
%PIP% --version || pip --version