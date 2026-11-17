@echo off
rem Starts the Python GUI. Needs 32-bit Python 3 and build_dll\game2048.dll
if not exist build_dll\game2048.dll (
    echo build_dll\game2048.dll not found. Run build_dll.bat first.
    exit /b 1
)
py -3-32 gui\gui.py build_dll\game2048.dll
if errorlevel 1 python gui\gui.py build_dll\game2048.dll
