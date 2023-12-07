I build this CPU using 74LS circuit  with some EEPROM. My goal was to try to make my own cpu and see if i can make it to work. All the microcode to control the machine is stored in 2 binary file to be programmed into 2864. Some external RAM is required to support the microcode

 0000H - 17FFH Total RAM space
 0000H - 00FFH Stack
 0100H - 17EF  Free for application
 17F0H SP		Stack Pointer 8 bit
 17F1H temp SP1
 17F2H temp	SP2
 17FAH bit<0>	Equal
 17FBH bit<0>	Carry
 17FCH A		Register
 17FEH IPH		Instruction Pointer MSB
 17FFH IPL		Instruction Pointer LSB

I started documenting this project when i saw all the other machines documented in this link:

Bloc Diagram of the architecture
![](BlocDiagram.jpg)

Picure of the final build connected to the Logic Analyzer
![](uct_picture1.jpg)
