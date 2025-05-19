@echo off

if not exist "%%ProgramData%%\chocolatey\bin\choco.exe" (
    echo Installing Chocolatey...
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    set PATH=%%PATH%%;%%ProgramData%%\chocolatey\bin
)

echo Installing LibreOffice SDK...
choco install libreoffice-sdk -y --no-progress --params="/AddToPath"
setx LibreOffice_DIR "C:\Program Files\LibreOffice\sdk" /M

refreshenv

echo Installing SQLite3...
choco install sqlite --installargs="ADDLOCAL=IncludeFiles,LibraryFiles" -y --no-progress
setx SQLite3_DIR "C:\Program Files\SQLite" /M

refreshenv

echo Installing Qt6 via choco...
choco install qtcreator -y --no-progress
choco install qt6 -y --no-progress --params="ADD_TO_PATH=1"
setx QT_DIR "C:\Qt\6.9.0\msvc2022_64" /M
setx PATH "%%PATH%%;C:\Qt\6.9.0\msvc2022_64\bin" /M

refreshenv

setx QT_DIR "C:\Qt\6.9.0\msvc2022_64" /M
setx PATH "%%PATH%%;C:\Qt\6.9.0\msvc2022_64\bin" /M

refreshenv

echo Verifying installations...
where libreoffice
where qmake
where sqlite3

echo Adding environment variables to current session...
set PATH=%%PATH%%;%%ProgramFiles%%\LibreOffice\program
set PATH=%%PATH%%;%%ProgramFiles%%\SQLite
set PATH=%%PATH%%;%%QT_DIR%%\bin

refreshenv

echo Required environment variables:
echo - Qt6_DIR: %%QT_DIR%%
echo - LibreOffice_DIR: %%LibreOffice_DIR%%
echo - SQLite3_DIR: %%SQLite3_DIR%%

refreshenv