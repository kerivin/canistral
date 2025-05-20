# PowerShell script for Windows dependencies with Chocolatey installation
param([switch]$SkipAdminCheck)

# Check if running as Administrator
if (-not $SkipAdminCheck) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Please run this script as Administrator" -ForegroundColor Red
        Write-Host "Alternatively, use -SkipAdminCheck if you're sure Chocolatey is already installed" -ForegroundColor Yellow
        exit 1
    }
}

# Function to refresh environment variables
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

# Install Chocolatey if not present
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey package manager..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Force refresh environment variables
        Refresh-Environment
        
        # Verify installation
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

# Install dependencies
Write-Host "Installing build dependencies..."
$packages = @(
    "libreoffice-fresh",
    "sqlite",
    "qt6-base-dev"
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."
    choco install -y $pkg
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install $pkg" -ForegroundColor Red
        exit 1
    }
}

# Final refresh
Refresh-Environment

# Verify installations
Write-Host "Verifying installations..."
$required = @{
    "cmake" = "cmake --version"
    "Qt" = "qmake --version"
    "SQLite" = "sqlite3 --version"
}

$missing = @()
foreach ($tool in $required.GetEnumerator()) {
    try {
        Invoke-Expression $tool.Value | Out-Null
    } catch {
        $missing += $tool.Key
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Missing tools: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "All dependencies installed successfully!" -ForegroundColor Green