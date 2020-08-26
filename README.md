# patroni-windows-packaging
Automate installing and launching of Patroni under Windows

## Install
Please check the [Setup Guide](doc/setup.md)

## Build
1. Run `make.bat`
2. Deploy `PES.zip` or `Patroni-Env-Setup.exe` installer

**Dependencies**:
* `curl`
* `PowerShell`
* [Inno Setup](https://github.com/jrsoftware/issrc)

`curl` and `powershell` both present in Windows 10 build 17063 and later. However, one may install them on earlier OSes and get the same result.
