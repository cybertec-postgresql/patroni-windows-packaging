@ECHO off

SET PYTHON=%LOCALAPPDATA%\Programs\Python\Python38\python.exe
SET PIP=%LOCALAPPDATA%\Programs\Python\Python38\Scripts\pip3.exe

@ECHO --- Installing Python runtime ---
python-install.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0
@ECHO --- Python runtime installed ---

@ECHO --- Installing Patroni packages ---
%PYTHON% -m pip install --upgrade pip
CD patroni
%PIP% install --no-index --find-links .patroni-packages -r requirements.txt
%PIP% install --no-index --find-links .patroni-packages psycopg2-binary
@ECHO --- Patroni packages installed ---

@PAUSE