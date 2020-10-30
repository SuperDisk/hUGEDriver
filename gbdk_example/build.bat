:: Assemble the hUGEDriver source into an RGBDS object file
rgbasm -ohUGEDriver.obj -i.. ../hUGEDriver.asm

:: Convert the RGBDS object file into a GBDK object file
rgb2sdas hUGEDriver.obj

:: Build the rom!
lcc -I../include -o output.gb gbdk_player_example.c hUGEDriver.obj.o sample_song.c