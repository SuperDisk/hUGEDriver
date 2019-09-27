@echo off

mkdir obj
mkdir bin

rgbasm -o obj\driver.o src\driver.asm
if %errorlevel% neq 0 call :exit 1

rgblink -m bin\hUGEDriver.map -n bin\hUGEDriver.sym -o bin\hUGEDriver.gb obj\driver.o
if %errorlevel% neq 0 call :exit 1
rgbfix -p 0xFF -v bin\hUGEDriver.gb
if %errorlevel% neq 0 call :exit 1
call :exit 0

:exit
exit
