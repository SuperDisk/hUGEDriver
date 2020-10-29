rgbasm -ohUGEDriver.obj -i.. ../hUGEDriver.z80
rgbasm -osample_song.obj -i.. sample_song.asm
rgbasm -oplayer.obj -i.. -DSONG_DESCRIPTOR=ryukenden ../player.z80

rgblink -ooutput.gb player.obj hUGEDriver.obj sample_song.obj
rgbfix -p0 -v output.gb