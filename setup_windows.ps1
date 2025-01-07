Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Get-Content .\choco\packages.txt | ForEach-Object {
    choco install -y $_
}

wsl --set-default-version 2

winget install -e -i --id=9MZNMNKSM73X --source=msstore