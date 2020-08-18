@ECHO off

SET PYTHON_REF=https://www.python.org/ftp/python/3.8.3/python-3.8.3-amd64.exe
SET PYTHON=%LOCALAPPDATA%\Programs\Python\Python38\python.exe
SET PIP=%LOCALAPPDATA%\Programs\Python\Python38\Scripts\pip3.exe

curl %PYTHON_REF% --output python-install.exe
python-install.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0
%PYTHON% -m pip install --upgrade pip