rgbasm -ohUGEDriver.obj -i.. ../hUGEDriver.z80
rgb2sdas hUGEDriver.obj
lcc -o output.gb gbdk_player_example.c hUGEDriver.obj.o sample_song.c