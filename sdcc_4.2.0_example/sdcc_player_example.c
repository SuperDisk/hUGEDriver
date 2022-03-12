#include "hUGEDriver.h"

extern const hUGESong_t ryukenden;

static volatile __sfr __at(0x40) lcdc;
static volatile __sfr __at(0x41) stat;
#define LCDC_ON     (char)(0x80)
#define STAT_MODE   (char)(0x03)


void wait4vblank(){
    if(!(lcdc & LCDC_ON))
        return;
    while((stat & STAT_MODE) == 1);
    while((stat & STAT_MODE) != 1);
}

void main() {
    hUGE_init_fast(&ryukenden); 
    while(1) {
        wait4vblank();
        hUGE_dosound();
    }
}
