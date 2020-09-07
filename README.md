# hUGEDriver
The sound driver/playback routine for [hUGETracker](https://github.com/SuperDisk/hUGETracker)

This is the repository for hUGETracker's playback routine. Check driver-format.txt for information about the code.

File list:

| File              | Explanation                                                                                                                                        |
|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| constants.inc     | Some note constant values. These values are mapped to actual frequency/periods in music.inc                                                        |
| HARDWARE.inc      | Constants that label some Gameboy hardware registers. Almost every Gameboy project uses this.                                                      |
| music.inc         | A table that maps the note constants (byte size) to periods that can be fed into the hardware registers (short size)                               |
| driver-format.txt | A text file explaining the layout of parts of the driver, and what formats are expected by certain routines.                                       |
| driver.z80        | The actual code.                                                                                                                                   

## Scripts

| File                   | explanation                                                                                                 |
|------------------------|-------------------------------------------------------------------------------------------------------------|
| 4ify.py                | A script to convert .raw files into 4 bit waves to preview how they would sound played by the noise channel |
| eevee_resamp.py        | A resampler written by [Eevee](http://eev.ee) that actually converts wave files to a 4 bit format. |
| generate_constants.py  | Was used to generate constants.inc                                                                          |
| vibrato_percentages.py | Was used to mess around with what sort of vibrato waveforms could be created. Basically useless.            |

# License

hUGETracker itself is licensed under the GPLv2, however this driver is dedicated to the public domain.
