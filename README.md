# 68060 in Macintosh Quadra650
This project is a collection of ROM modifications to get a minimum level of functionality out of a Macintosh Quadra 650/800 / Centris 650 with a 68060 installed on an appropriate adapter. As currently sits it can boot an unmodified System 7.1 install. Much will not work and remains to be done; I do not expect to finish it.

Thanks to Jockelill for a pointer on the MMU ROM mapping and Aprezbios for supplying scrap 060s to play with.

PROOF: https://www.youtube.com/watch?v=KXSWiKu-ASA

This is a experimental proof of concept ONLY and no warranty is expressed or implied. 
Please don't rush out to replicate this unless you know what you're doing!

## Building
Build Retro68 or a standard m68K GCC toolchain and point the makefile at it. Issue make and pray.
Flash the resulting image to a Quadra-compatible ROM SIMM such as those sold by Caymac.

## License
I assert no ownership to any material in this repository. Do with it what you will.
*Licenses of reference content vary, please credit the original teams appropriately.*