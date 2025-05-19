echo Installing LibreOffice SDK...
choco install libreoffice-sdk -y --params="/AddToPath"
setx LibreOffice_DIR "C:\Program Files\LibreOffice\sdk" /M

echo Downloading Qt6 installer...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://download.qt.io/official_releases/online_installers/qt-unified-windows-x64-online.exe', 'qt-installer.exe')"

echo Running Qt6 installer (minimal installation)...
start /wait qt-installer.exe --script https://gist.githubusercontent.com/username/yourqtinstallscript/raw/script.qs
del qt-installer.exe

setx QT_DIR "C:\Qt\6.5.0\msvc2019_64" /M
setx PATH "%PATH%;C:\Qt\6.5.0\msvc2019_64\bin" /M

echo Installing SQLite3...
choco install sqlite --installargs="ADDLOCAL=IncludeFiles,LibraryFiles" -y
setx SQLite3_DIR "C:\Program Files\SQLite" /M

echo Verifying installations...
where libreoffice
where qmake
where sqlite3

echo Adding environment variables to current session...
set PATH=%PATH%;%ProgramFiles%\LibreOffice\program
set PATH=%PATH%;%ProgramFiles%\SQLite
set PATH=%PATH%;%QT_DIR%\bin

echo Required environment variables:
echo - QT_DIR: %QT_DIR%
echo - LibreOffice_DIR: %LibreOffice_DIR%
echo - SQLite3_DIR: %SQLite3_DIR%

refreshenv