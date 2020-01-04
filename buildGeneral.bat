@echo off
rgbasm -opreview.obj driverLite.z80
if %errorlevel% neq 0 call :exit 1
rgblink -mpreview.map -npreview.sym -opreview.gb preview.obj
if %errorlevel% neq 0 call :exit 1
rgbfix -p0 -v preview.gb
if %errorlevel% neq 0 call :exit 1
call :exit 0

:exit
exit