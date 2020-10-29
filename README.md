# hUGEDriver
The sound driver/playback routine for [hUGETracker](https://github.com/SuperDisk/hUGETracker)

This is the repository for hUGETracker's playback routine.

# How to use (RGBDS)


# How to use (GBDK)

1. Export your song in "GBDK .c" format in hUGETracker.
2. Choose a "song descriptor" name. This is what you will refer to the song as in your code.
3. Place the exported .C file in your GBDK project.
4. `#include "hUGEDriver.h"` in your game's main file
5. Define `extern const hUGESong_t your_song_descriptor_here` in your game's main file
6. Call `hUGE_init(&your_song_descriptor_here)` in your game's main file
7. In your game's main loop or in a VBlank interrupt, call `hUGE_dosound`
8. When compiling your game, be sure to specify your music file and hUGEDriver.o in your call to LCC!

See `gbdk/gbdk_player_example.c` for a working example!


# Files in this repo

| File                  | Explanation                                                                                                         |
|-----------------------|---------------------------------------------------------------------------------------------------------------------|
| hUGEDriver.z80        | The driver itself.                                                                                                  |
| song.z80              | A template used to create a song descriptor for use by the driver.                                                  |
| player.z80            | Some example code that illustrates how to initialize and use the driver. Also used by hUGETracker to preview music. |
| gbs.z80               | Used by hUGETracker to build GBS soundtrack files.                                                                  |
| gbdk/hUGEDriver.h     | A C header that allows for usage of hUGEDriver in GBDK projects.                                                    |
| include/constants.inc | Some note constant values. These values are mapped to actual frequency/periods in music.inc                         |
| include/music.inc     | A table that maps the note constants (byte size) to periods that can be fed into the hardware registers (word size) |
| doc/driver-format.txt | A text file explaining the layout of parts of the driver, and what formats are expected by certain routines.        |

# License

hUGETracker itself is licensed under the GPLv2, however this driver is dedicated to the public domain.
