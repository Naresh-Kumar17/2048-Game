@echo off
rem ============================================================
rem build_dll.bat - builds the assembly engine as build_dll\game2048.dll
rem Run from the repo root. Change IRVINE / VCVARS if your paths differ.
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

if not exist build_dll mkdir build_dll
cd build_dll
if exist game2048.dll del /q game2048.dll

ml /c /coff /nologo /I %IRVINE% /I ..\include ..\src\api.asm ..\src\data.asm ..\src\logic.asm ..\src\spawn.asm ..\src\state.asm
if errorlevel 1 goto failed

link /nologo /DLL /SUBSYSTEM:WINDOWS /SAFESEH:NO /INCREMENTAL:NO /DEF:..\gui\game2048.def /LIBPATH:%IRVINE% api.obj data.obj logic.obj spawn.obj state.obj irvine32.lib kernel32.lib user32.lib /OUT:game2048.dll
if errorlevel 1 goto failed
if not exist game2048.dll goto failed

echo.
echo Exports of the DLL:
dumpbin /exports game2048.dll | findstr /i "Game_"
cd ..
echo.
echo BUILD OK  ->  build_dll\game2048.dll
echo Start the GUI with:  run_gui.bat
exit /b 0

:failed
cd ..
echo.
echo BUILD FAILED - read the first error above (fix errors from the top down)
exit /b 1
