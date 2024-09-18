# Set the environment variables
. .\env.ps1

Remove-Item -Recurse -Force "$MD", "patroni" -ErrorAction SilentlyContinue
Remove-Item -Force `
    "*.zip", `
    "*.exe", `
    "$env:TEMP\etcd.zip", `
    "$env:TEMP\pes.zip", `
    "$env:TEMP\micro.zip", `
    "$env:TEMP\vip.zip", `
    "$env:TEMP\pgsql.zip", `
    "$env:TEMP\patroni.zip" `
    -ErrorAction SilentlyContinue