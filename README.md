Homebrew CPU Project (74LS Logic + EEPROM)
I built this CPU at home using 74LS logic ICs and EEPROMs, driven by curiosity and a desire to understand processor design at a fundamental level.



Project Overview
My goal was to create a fully functional CPU using a 1-bit ALU. While this results in relatively slow execution speeds, it allows me to explore the control and datapath mechanisms in detail. All microcode for the CPU is stored in two binary files and programmed into 2864 EEPROM chips. A custom microassembler was written to generate these micro-instructions.

Wire-Wrap Prototype
Before moving to a PCB, I built a wire-wrap prototype to test the design on real hardware. This stage was essential for debugging the microcode, verifying timing, and refining the instruction set.

![](cpuPicture1.jpg)

Wire-wrapping made it easier to make changes during development while still providing a reliable and compact way to interconnect components.

PCB Version Sponsored by PCBWay
With the core architecture proven on the wire-wrap prototypes, I'm now working on a custom PCB version of the CPU. This step is generously sponsored by PCBWay.

Here’s a snapshot of the ongoing KiCad design:

![](MyCPU_PCB.jpg)

Stay tuned for updates! The full source code, schematics, microcode files, and PCB layout will be shared as the project progresses.


The design also uses external RAM to support the CPU’s operation. Here is the memory address map used:

0000H - 17FFH Total RAM space
-----------------------------
* 0000H - 17FFH Total RAM space
* 0000H - 00FFH Stack
* 0100H - 17EF  Free for application
* 1FF0H SP      Stack Pointer 8 bit
* 1FF1H JSH     Temporary storage for JSR MSB address
* 1FF2H JSL          "       "     "   "  LSB    "
* 1FF3H XH      Index Register MSB
* 1FF4H XL      Index Register LSB
* 1FFAH E       bit<0> Equal Status bit
* 1FFBH C       bit<0> Carry Status bit
* 1FFCH A       Register
* 1FFEH IPH	    Instruction Pointer MSB
* 1FFFH IPL     Instruction Pointer MSB
* C000H         LED port
* E000H - F000H EEPROM for application program


Register A, Stack Pointer, Status flag and Instruction Pointer are stored in RAM. This is purely to save on chip count at the expense of a slower machine.

Here is the top level diagram of this relatively simple architecture.
![](topDiagram.jpg)

The hand written schematic
![](cpuSchematic.jpg)

The cpu board layout view
![](cpuBoardLayout.jpg)

The ROM decoding table encodes the different combinations of how data can travel between the components. This ROM expands the number of lines we can control with the EEPROM microcode, saving the number of bits required. This architecture works using 16-bits micro-instructions. The chips IC20 and IC21 are 74S188 256 Open Collector PROMs (really one-time programmable). Several chips were lost before finding the correct table values.
![](decoderRomTable.jpg)

The io board schematic. A RAM, EEPROM to store the application program with some LEDs.
![](ioSchematic.jpg)

Single clock step debug sessions starting from reset, using only a couple of LEDs to inspect ucode address and main bus byte display, became too painfull. I finally purchased a reasonably priced Agilent 1670G Logic Analyzer on eBay and connected it to MyCpu to obtain a better history of program exection, easing the debugging process. Using symbol assignment, it is possible to perform some rudimentary microcode dissassembly.
Picure of the final wire wrap assembly connected to the Logic Analyzer
![](cpuPicture2.jpg)

A view on the analyzer showing some microcode dissassembly.
![](ucodeLogicAnalyzerDebug.jpg)

I began documenting this project when i encountered other wonderfull machines showcased in this link: Homebuilt CPUs WebRing
Definitely check out other awesome homebrew CPU builds on Warren's https://www.homebrewcpuring.org

Interested in joining the ring?
To join the Homebuilt CPUs ring, drop Warren a line (mail is obfuscated, you have to change [at] to @), mentioning your page's URL. He'll then add it to the list. You will need to copy this code fragment into your page (or reference it.)
Note: The ring is chartered for projects that include a home-built CPU. It can emulate a commercial part, that′s OK. But actually using that commercial CPU doesn′t rate. Likewise, the project must have been at least partially built: pure paper designs don′t rate either. It can be built using any technology you like, from relays to FPGAs.
