rgbasm -ohUGEDriver.obj -i.. ../hUGEDriver.z80
rgbasm -osong.obj -i.. -isample_song sample_song/song.z80
rgbasm -oplayer.obj -i.. ../player.obj

rgblink -ooutput.gb player.obj hUGEDriver.obj song.obj
rgbfix -p0 -v output.gb