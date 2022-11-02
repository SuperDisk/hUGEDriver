TOOLS=../tools
GBDK=../../gbdk

all:
	#Assemble the hUGEDriver source into an RGBDS object file
	rgbasm -DGBDK -ohUGEDriver.obj -i.. ../hUGEDriver.asm

	#Convert the RGBDS object file into a GBDK object file
	$(TOOLS)/rgb2sdas hUGEDriver.obj

	#Build the rom!
	$(GBDK)/bin/lcc -I../include -o output.gb gbdk_player_example.c hUGEDriver.obj.o sample_song.c
