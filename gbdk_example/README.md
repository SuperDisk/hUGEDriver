This is a simple example of how to use hUGEDriver in your GBDK game.

Make sure you have both GBDK and RGBDS in your path, then run `build.bat` to build a .gb file which plays some music!

In `build.bat`, the steps are:

```bat
:: Assemble the hUGEDriver source into an RGBDS object file
rgbasm -ohUGEDriver.obj -i.. ../hUGEDriver.asm

:: Convert the RGBDS object file into a GBDK object file
rgb2sdas hUGEDriver.obj

:: Build the rom!
lcc -o output.gb gbdk_player_example.c hUGEDriver.obj.o sample_song.c
```

You can run `output.gb` in your favorite Gameboy emulator.
