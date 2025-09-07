# Assemble the hUGEDriver source into an object
/home/npfaro/projects/hUGETracker/src/lib/Development/x86_64-linux/rgbasm -ohUGEDriver.obj -I../include -I.. ../hUGEDriver.asm

# Assemble the song into an object
/home/npfaro/projects/hUGETracker/src/lib/Development/x86_64-linux/rgbasm -osample_song.obj -I../include -I.. sample_song.asm

# Assemble the example player code into an object
/home/npfaro/projects/hUGETracker/src/lib/Development/x86_64-linux/rgbasm -oplayer.obj -I../include -I.. -DSONG_DESCRIPTOR=sample_song ../player.asm

# Link the objects together and run rgbfix
/home/npfaro/projects/hUGETracker/src/lib/Development/x86_64-linux/rgblink -ooutput.gb -noutput.sym -moutput.map player.obj hUGEDriver.obj sample_song.obj
/home/npfaro/projects/hUGETracker/src/lib/Development/x86_64-linux/rgbfix -p0 -fhg output.gb
