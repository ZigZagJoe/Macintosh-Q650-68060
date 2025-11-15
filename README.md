# 68060 in Macintosh Quadra 650
This project is a collection of ROM modifications to get a minimum level of functionality out of a Macintosh Quadra 650/800 / Centris 650 with a Motorola 68060 CPU installed on an appropriate adapter. As currently sits it can boot an unmodified System 7.1 install. Much will not work and further work is required to bring into a truly usable state; I do not expect to finish it.

[Boot video @ youtube](https://www.youtube.com/watch?v=KXSWiKu-ASA)
[Writeup @ 68kmla](https://68kmla.org/bb/index.php?threads/macintosh-68060-redux.51016/)

This is a experimental proof of concept ONLY. **Do not expect it to be usable**! Please don't rush out to replicate this unless you know *exactly* what you're getting into, or you will be disappointed. No warranty is expressed or implied; I'm not responsible if your Macintosh catches fire, attains sentience, or is raptured into an alternate reality where 68K won the CPU wars. 

Thanks to Jockelill for a pointer on the MMU ROM mapping, Aprezbios for supplying scrap 060s to play with, and Reinauer for his open source [68040-68060](https://github.com/reinauer/68040-to-68060) adapter.

## Requirements
* System 7.1 + System Enabler 040 V1.1
* System gestalt ID 36 for Quadra 650 (J25 disconnected, R152 installed, R151 empty)
* Any version of 68060, LC chips should work too. Note: if your machine is 33mhz, not all 060s will run at 66mhz!

## Building
Build [Retro68](https://github.com/autc04/Retro68) or a standard m68K GCC toolchain and point the Makefile at it. Issue make and pray.
Flash the resulting image to a Quadra-compatible ROM SIMM such as those sold by Caymac, install a 68060 on an appropriate adapter, and let 'er rip.

## License
I do not assert ownership of material in this repository. Do with it what you will, but credit is appreciated :)

The Macintosh ROM is property of Apple Computer.

*Licenses of reference content vary, please see the licenses in the respective directories for details.*