@echo off
rgbasm -opreview.obj driverLite.z80
if %errorlevel% neq 0 call :exit 1
rgblink -opreview.gbs preview.obj
if %errorlevel% neq 0 call :exit 1
call :exit 0

:exit
exit