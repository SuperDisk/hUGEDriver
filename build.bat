@echo off

mkdir obj
mkdir bin

rgbasm -p 0xFF -h -i src/ -i src/include/ -o obj\songs.o      src\songs.asm
if %errorlevel% neq 0 call :exit 1
rgbasm -p 0xFF -h -i src/ -i src/include/ -o obj\driver_mem.o src\driver_mem.asm
if %errorlevel% neq 0 call :exit 1
rgbasm -p 0xFF -h -i src/ -i src/include/ -o obj\main.o       src\main.asm
if %errorlevel% neq 0 call :exit 1
rgbasm -p 0xFF -h -i src/ -i src/include/ -o obj\driver.o     src\driver.asm
if %errorlevel% neq 0 call :exit 1

rgblink -p 0xFF -m bin\hUGEDriver.map -n bin\hUGEDriver.sym -o bin\hUGEDriver.gb -d obj\main.o obj\driver.o
if %errorlevel% neq 0 call :exit 1
rgbfix -p 0xFF -v -i HUGE -k HB -l 0x33 -m 0 -n 0 -r 0 -t hUGEDriver bin\hUGEDriver.gb
if %errorlevel% neq 0 call :exit 1
call :exit 0

:exit
exit
