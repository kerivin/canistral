@echo off
echo Installing LibreOffice SDK...
choco install libreoffice-sdk -y --params="/AddToPath"
setx LibreOffice_DIR "C:\Program Files\LibreOffice\sdk" /M

refreshenv

echo Installing Qt6 via choco...
choco install qtcreator -y
choco install qt6 -y --params="ADD_TO_PATH=1"
setx QT_DIR "C:\Qt\6.9.0\msvc2022_64" /M
setx PATH "%PATH%;C:\Qt\6.9.0\msvc2022_64\bin" /M

refreshenv

setx QT_DIR "C:\Qt\6.9.0\msvc2022_64" /M
setx PATH "%PATH%;C:\Qt\6.9.0\msvc2022_64\bin" /M

refreshenv

echo Installing SQLite3...
choco install sqlite --installargs="ADDLOCAL=IncludeFiles,LibraryFiles" -y
setx SQLite3_DIR "C:\Program Files\SQLite" /M

refreshenv

echo Verifying installations...
where libreoffice
where qmake
where sqlite3

echo Adding environment variables to current session...
set PATH=%PATH%;%ProgramFiles%\LibreOffice\program
set PATH=%PATH%;%ProgramFiles%\SQLite
set PATH=%PATH%;%QT_DIR%\bin

refreshenv

echo Required environment variables:
echo - Qt6_DIR: %QT_DIR%
echo - LibreOffice_DIR: %LibreOffice_DIR%
echo - SQLite3_DIR: %SQLite3_DIR%

refreshenv