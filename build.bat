@echo off
rem ============================================================
rem build.bat - builds Game2048.exe into the build folder
rem Run from the repo root, inside "x86 Native Tools Command Prompt for VS"
rem Change IRVINE below if your Irvine library is somewhere else.
rem ============================================================
set IRVINE=C:\Irvine
set VCVARS=C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars32.bat
where ml >nul 2>nul
if errorlevel 1 (
    if exist "%VCVARS%" (
        call "%VCVARS%"
    ) else (
        echo Cannot find Visual Studio tools. Edit VCVARS at the top of this file.
        exit /b 1
    )
)

if not exist build mkdir build
cd build

ml /c /coff /Zi /nologo /I %IRVINE% /I ..\include ..\src\data.asm ..\src\logic.asm ..\src\spawn.asm ..\src\state.asm ..\src\ui.asm ..\src\input.asm ..\src\main.asm
if errorlevel 1 goto failed

if exist Game2048.exe del /q Game2048.exe
echo.
echo Linker being used:
where link
link /nologo /SUBSYSTEM:CONSOLE /SAFESEH:NO /DEBUG /INCREMENTAL:NO /LIBPATH:%IRVINE% data.obj logic.obj spawn.obj state.obj ui.obj input.obj main.obj irvine32.lib kernel32.lib user32.lib /OUT:Game2048.exe
if errorlevel 1 goto failed
if not exist Game2048.exe goto failed

echo.
echo ---- Check of the result ----
dir Game2048.exe | findstr /i "Game2048"
dumpbin /headers Game2048.exe | findstr /i "machine subsystem"
echo ------------------------------

cd ..
echo.
echo BUILD OK  ->  build\Game2048.exe
echo Run it with:  build\Game2048.exe
exit /b 0

:failed
cd ..
echo.
echo BUILD FAILED - read the first error above (fix errors from the top down)
exit /b 1
