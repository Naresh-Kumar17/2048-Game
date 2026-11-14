@echo off
setlocal enabledelayedexpansion
rem ============================================================
rem test.bat - builds and runs ONE test program
rem Usage (from the repo root, in x86 Native Tools Command Prompt):
rem    test.bat board | slideline | moveboard | spawn | state | ui
rem Change IRVINE below if your Irvine library is somewhere else.
rem ============================================================
set IRVINE=C:\Irvine
set T=%1
set FILES=
if "%T%"=="board"     set FILES=..\tests\test_board.asm ..\src\logic.asm
if "%T%"=="slideline" set FILES=..\tests\test_slideline.asm ..\src\logic.asm
if "%T%"=="moveboard" set FILES=..\tests\test_moveboard.asm ..\src\logic.asm
if "%T%"=="spawn"     set FILES=..\tests\test_spawn.asm ..\src\spawn.asm
if "%T%"=="state"     set FILES=..\tests\test_state.asm ..\src\logic.asm ..\src\spawn.asm ..\src\state.asm
if "%T%"=="ui"        set FILES=..\tests\test_ui.asm ..\src\ui.asm ..\src\input.asm
if "%FILES%"=="" (
    echo Usage: test.bat board^|slideline^|moveboard^|spawn^|state^|ui
    exit /b 1
)

if not exist build_test_%T% mkdir build_test_%T%
cd build_test_%T%
del /q *.obj 2>nul

ml /c /coff /Zi /nologo /I %IRVINE% /I ..\include %FILES%
if errorlevel 1 goto failed

set OBJS=
for %%f in (*.obj) do set OBJS=!OBJS! %%f
link /nologo /SUBSYSTEM:CONSOLE /SAFESEH:NO /DEBUG /INCREMENTAL:NO /LIBPATH:%IRVINE% !OBJS! irvine32.lib kernel32.lib user32.lib /OUT:test_%T%.exe
if errorlevel 1 goto failed

test_%T%.exe
cd ..
exit /b 0

:failed
cd ..
echo.
echo BUILD FAILED - read the first error above (fix errors from the top down)
exit /b 1
