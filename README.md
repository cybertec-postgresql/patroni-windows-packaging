# patroni-windows-packaging
Automate installing and launching of Patroni under Windows

## TL;DR
1. Run `install-env.bat` and reopen the console to update `PATH` and `PATHEXT` environment variables
2. Run `make.bat`
3. Deploy `patroni-win-x64.zip`

## Dependencies
* curl
* PowerShell

Both present in Windows 10 build 17063 and later. However, one may install curl and\or PowerShell on earlier OSes and get the same result.
