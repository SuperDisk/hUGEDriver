.SUFFIXES:


SDCCBIN=
RGBDSBIN=
CC=$(SDCCBIN)sdcc
CFLAGS=-msm83 -I../include 
AS=$(RGBDS)rgbasm
ASFLAGS=-DSDCC_FAST
MKROM=$(SDCCBIN)makebin

.PHONY: all clean

all: output.gb

%.obj: ../%.asm
	$(AS) $(ASFLAGS) -o$@ -i.. $^

%.obj.o: %.obj ../tools/rgb2sdas
	../tools/rgb2sdas hUGEDriver.obj $<
	sed "s/O -mgbz80//g" -i $@

%.rel: %.obj.o
	cp $< $@

%.rel: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

sample_song.rel: ../gbdk_example/sample_song.c
	$(CC) $(CFLAGS) -c -o $@ $^

%.ihx: sdcc_player_example.rel hUGEDriver.rel sample_song.rel
	$(CC) $(CFLAGS) --out-fmt-ihx -o $@ $^

%.gb: %.ihx
	$(MKROM) -Z -yS $< $@

../tools/rgb2sdas:
	make -C ../tools

clean:
	$(RM) *.gb *.lst *.noi *.map *.rel *.asm *.sym *.ihx *.obj *.obj.o *.lk