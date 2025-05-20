param([switch]$SkipAdminCheck)

if (-not $SkipAdminCheck) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Please run this script as Administrator" -ForegroundColor Red
        Write-Host "Alternatively, use -SkipAdminCheck if you're sure Chocolatey is already installed" -ForegroundColor Yellow
        exit 1
    }
}

function Refresh-Environment {
    foreach ($level in "Machine", "User") {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            if ($_.Name -eq 'PATH') {
                $existingPaths = $env:PATH -split ';' | Where-Object { $_ }
                $newPaths = $_.Value -split ';' | Where-Object { $_ }
                $combinedPaths = ($existingPaths + $newPaths) | Select-Object -Unique
                $env:PATH = $combinedPaths -join ';'
            } else {
                Set-Item -Path "Env:\$($_.Name)" -Value $_.Value
            }
        }
    }
}

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey package manager..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        Refresh-Environment
        
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "Chocolatey installed but not in PATH. Trying manual refresh..." -ForegroundColor Yellow
            $chocoPath = "$env:ProgramData\chocolatey\bin"
            if (Test-Path $chocoPath) {
                $env:PATH += ";$chocoPath"
            }
        }
        
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            throw "Chocolatey installation failed"
        }
    } catch {
        Write-Host "Failed to install Chocolatey: $_" -ForegroundColor Red
        exit 1
    }
}