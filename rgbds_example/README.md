This is a simple example of how to use hUGEDriver in your game.

Make sure you have RGBDS in your path, then run `build.bat` to build a .gb file which plays some music!

In `build.bat` the steps are:

```bat
:: Assemble the hUGEDriver source into an object
rgbasm -ohUGEDriver.obj -i.. ../hUGEDriver.z80

:: Assemble the song into an object
rgbasm -osample_song.obj -i.. sample_song.asm

:: Assemble the example player code into an object
:: We specify -DSONG_DESCRIPTOR=ryukenden because that's the song descriptor I chose when exporting the song in hUGETracker.
rgbasm -oplayer.obj -i.. -DSONG_DESCRIPTOR=ryukenden ../player.z80

:: Link the objects together and run rgbfix
rgblink -ooutput.gb player.obj hUGEDriver.obj sample_song.obj
rgbfix -p0 -v output.gb
```

You can run `output.gb` in your favorite Gameboy emulator.
