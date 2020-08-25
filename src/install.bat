REM This script is for back compatibility only. Use install.ps1 instead!
@ECHO off

SET PYTHON=python.exe


@ECHO --- Installing Python runtime ---
python-install.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0
%PYTHON% -m pip install --upgrade pip
@ECHO --- Python runtime installed ---

START cmd.exe /k install-packages.bat

@PAUSE