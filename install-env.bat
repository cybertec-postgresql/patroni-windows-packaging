SET PYTHON_REF=https://www.python.org/ftp/python/3.8.3/python-3.8.3-amd64.exe

@ECHO --- Download PYTHON ---
curl %PYTHON_REF% --output python-install.exe
python-install.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
python -m pip install --upgrade pip