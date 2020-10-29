![hUGEDriver](https://nickfa.ro/images/Hugedriver2.gif)
---

# Quick start (RGBDS)
1. Export your song in "RGBDS .htt" format in hUGETracker.
2. Choose a *song descriptor* name. This is what you will refer to the song as in your code. It must be a valid RGBDS symbol.
3. Place the exported folder of `.htt` files in your RGBDS project.
4. Load `hl` with your song descriptor name, and `call hUGE_init`
5. In your game's main loop or in a VBlank interrupt, `call hUGE_dosound`
6. When assembling your game, be sure to specify your music file and hUGEDriver.z80 in your call to `rgbasm`/`rgblink`!

See the `rgbds_example` directory for a working example!

# Quick start (GBDK)

1. Export your song in "GBDK .c" format in hUGETracker.
2. Choose a *song descriptor* name. This is what you will refer to the song as in your code. It must be a valid C variable name.
3. Place the exported .C file in your GBDK project.
4. `#include "hUGEDriver.h"` in your game's main file
5. Define `extern const hUGESong_t your_song_descriptor_here` in your game's main file
6. Call `hUGE_init(&your_song_descriptor_here)` in your game's main file
7. In your game's main loop or in a VBlank interrupt, call `hUGE_dosound`
8. When compiling your game, be sure to specify your music file and hUGEDriver.o in your call to `lcc`!

See `gbdk_example/gbdk_player_example.c` for a working example!

# Usage

This driver is suitable for use in homebrew games. hUGETracker exports data representing the various compoennts of a song, as well as a *song descriptor* which is a small block of pointers that tell the driver how to initialize and play a song.

hUGETracker can export the data and song descriptor as a `.asm` or `.c` for use in RGBDS or GBDK based projects, respectively. Playing a song is as simple as calling hUGE_init with a pointer to your song descriptor, and then calling `hUGE_dosound` at a regular interval (usually on VBlank, the timer interrupt, or simply in your game's main loop)

In assembly:
```asm
ld hl, SONG_DESCRIPTOR
call hUGE_init

;; Repeatedly
call _hUGE_dosound
```

In C:
```c
extern const hUGESong_t song;

// In your initializtion code
__critical {
    hUGE_init(&song);
    add_VBL(hUGE_dosound);
}
```

Check out `player.z80` for a full fledged example of how to use the driver in an RGBDS project, and `gbdk_example/gbdk_player_example.c` for usage with GBDK C likewise.

# Files in this repo

| File                  | Explanation                                                                                                         |
|-----------------------|---------------------------------------------------------------------------------------------------------------------|
| hUGEDriver.z80        | The driver itself.                                                                                                  |
| song.z80              | A template used to create a song descriptor for use by the driver.                                                  |
| player.z80            | Some example code that illustrates how to initialize and use the driver. Also used by hUGETracker to preview music. |
| gbs.z80               | Used by hUGETracker to build GBS soundtrack files.                                                                  |
| gbdk_example/hUGEDriver.h | A C header that allows for usage of hUGEDriver in GBDK projects.                                                    |
| include/constants.inc | Some note constant values. These values are mapped to actual frequency/periods in music.inc                         |
| include/music.inc     | A table that maps the note constants (byte size) to periods that can be fed into the hardware registers (word size) |
| doc/driver-format.txt | A text file explaining the layout of parts of the driver, and what formats are expected by certain routines.        |

# License

This driver is dedicated to the public domain.
