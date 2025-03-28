// Homebrew MyCPU assembler program
// Author: Sylvain Fortin  sylfortin71@hotmail.com
// Date: 27 march 2024
// Documentation: This is an assembler program converting mnemonic for the MyCPU into OP code
//                that can be executed by the micro-program. The source file having an extension .asm 
//                is passed in argument in the command line.
//                Two output files are created:
//                - filename.lst is an ascii file of the listing containing the address, op code, operand
//                with the comments.
//                - filename.bin contain the binary data to be programmed on the EEPROM.
//                The EEPROM programmer i am using is model TL866II Plus from XGecu.

using System;
using System.IO;
using System.Collections.Generic;

namespace Assembler
{
    public class InstrTable
    {
        public string StringValue { get; set; }
        public int OpCode { get; set; }
        public int NbByte { get; set; }
        public int Sym { get; set; }        public int Offset { get; set; }
    }

    class SymbolTableEntry
    {
        public string Symbol { get; set; }
        public int Address { get; set; }
    }

    class Program
    {
        // Declare symbolTable as a static member
        private static Dictionary<string, SymbolTableEntry> symbolTable = new Dictionary<string, SymbolTableEntry>();

        // Function to check if a string is a valid hexadecimal value
        static bool IsHex(string hexValue)
        {
            foreach (char c in hexValue)
            {
                if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F')))
                {
                    return false;
                }
            }
            return true;
        }

        static void getNibble(string sNibble, ref int iNibble, ref int iErrorNumber)
        {
            // Check if the string is a valid hexadecimal value
            if (!(IsHex(sNibble)))
            {
                Console.WriteLine();
                // Add logic for printing to a file or console (similar to PRINT statements in BASIC)
                Console.WriteLine("**** ERREUR SUR VALEUR HEXADECIMALE (0-9,A-F) ****");
                Console.WriteLine("**** ERREUR SUR VALEUR HEXADECIMALE (0-9,A-F) ****");  // .LST
                iErrorNumber++;
                iNibble = 0;
            }
            else
            {
                // Convert hexadecimal string to integer
                iNibble = int.Parse(sNibble, System.Globalization.NumberStyles.HexNumber);
            }

            // Continue with the logic after the IF statement
            // ...
        }

        static int FindNextNonSpaceCharacter(string input, int startIndex)
        {
            for (int i = startIndex; i < input.Length; i++)
            {
                if (input[i] != ' ')
                {
                    return i; // Return the index of the next non-space character
                }
            }

            return -1; // Return -1 if no non-space character is found after the startIndex
        }

//        static void PrintSymbolTable()
//        {
//            Console.WriteLine("Symbol Table:");
//            foreach (var entry in symbolTable)
//            {
//                Console.WriteLine($"{entry.Key,-10}{entry.Value.Address:X4}");
//            }
//        }

        static void Main(string[] args)
        {
            bool bStopOnError = true;
            string sTemp;
            symbolTable = new Dictionary<string, SymbolTableEntry>();

            Console.WriteLine("Homebrew assembler start");
            string sCurrentPath = "";
            string sRepositoryPath = "";
            string sFileName = "";

            sFileName = args[0];
            if (args.Length != 1)   // No argument
            {
                sRepositoryPath = "C:\\Sylvain\\MyCPU\\opCodeAssembler\\examples";    // Fixed path for now
                sFileName = "fibonacy.asm"; // Replace with your desired file name
            }
            else
            {                       // With argument
                sCurrentPath = Directory.GetCurrentDirectory();
                sRepositoryPath = Path.Combine(sCurrentPath, "../../examples");           // Move up two level and go to examples

            }

            string baseFileName = Path.GetFileNameWithoutExtension(sFileName);
            string fileExtension = Path.GetExtension(sFileName);
            string fullPath = Path.Combine(sRepositoryPath, sFileName);

            int iAddressEepromBegin = 0xE000;

            // Reserve space for one 2864 EEPROM
            // we have 12 bit address (A12-A0)
            const int iEpromSize = 8192;
            int[] aEeprom = new int[iEpromSize];

            int iErrorNumber = 0;
            int iErrorNumberPass1 = 0;
            int iErrorNumberPass2 = 0;
            int iAddress = 0;
            int iTotalAssembledFieldWidth = 12; // number of character allowed to print assembled bytes.
            int iAssembledMnemonicPosition = 4 + iTotalAssembledFieldWidth; // 4 correspond to number of characters for the address

            List<InstrTable> dataList = new List<InstrTable>();
            // OpCode : Byte value used to code each instruction
            // NbByte : Number of bytes following the OP code byte
            // Sym    : Symbolic decoding is enabled after the mnemonic 0: hex address, 1:symbolic address, 2:symbolic relative adressing (+-127)
            // Offset : Character position where the hex value start.
            // Presently only hexadecimal values are supported, 8 and 16 bits only.
            dataList.Add(new InstrTable { StringValue = "ORG/0x****",   OpCode = 0,     NbByte = 0, Sym = 0, Offset = 6 }); // 
            dataList.Add(new InstrTable { StringValue = "DB 0x**",      OpCode = 0,     NbByte = 0, Sym = 0, Offset = 5 });  // Define Byte in EEPROM Memory
            dataList.Add(new InstrTable { StringValue = "EQU 0x",       OpCode = 0,     NbByte = 0, Sym = 0, Offset = 6 });  // Define Byte in EEPROM Memory
            dataList.Add(new InstrTable { StringValue = "JSR 0x****",   OpCode = 0x06,  NbByte = 2, Sym = 0, Offset = 6 });  // JSR ****H    Jump to SubRoutine
            dataList.Add(new InstrTable { StringValue = "JSR",          OpCode = 0x06,  NbByte = 2, Sym = 1, Offset = 4 });  // JSR sym
            dataList.Add(new InstrTable { StringValue = "RTS",          OpCode = 0x07,  NbByte = 0, Sym = 0, Offset = 0 });  // RTS          ReTurn from Subroutine
            dataList.Add(new InstrTable { StringValue = "STOP",         OpCode = 0x08,  NbByte = 0, Sym = 0, Offset = 0 });  // STOP         STOP Executing
            dataList.Add(new InstrTable { StringValue = "NOP",          OpCode = 0x09,  NbByte = 0, Sym = 0, Offset = 0 });  // NOP          No Operation
            dataList.Add(new InstrTable { StringValue = "LDA (X)",      OpCode = 0x0A,  NbByte = 0, Sym = 0, Offset = 0 });  // LDA (X)      Load Reg A Indexed
            dataList.Add(new InstrTable { StringValue = "STA (X)",      OpCode = 0x0B,  NbByte = 0, Sym = 0, Offset = 0 });  // STA (X)      Store Reg A Indexed
            dataList.Add(new InstrTable { StringValue = "JRA 0x**",     OpCode = 0x0C,  NbByte = 1, Sym = 0, Offset = 6 });  // JRA 0x**     Unconditional relative jump
            dataList.Add(new InstrTable { StringValue = "JRA @",        OpCode = 0x0C,  NbByte = 1, Sym = 2, Offset = 4 });  // JRA symbol   Unconditional relative jump
            dataList.Add(new InstrTable { StringValue = "SRLA",         OpCode = 0x0D,  NbByte = 0, Sym = 0, Offset = 0 });  // SRLA         Shift Right Logical on Reg A  0 -> b7 b6 b5 b4 b3 b2 b1 b0 -> C
            dataList.Add(new InstrTable { StringValue = "SLLA",         OpCode = 0x0E,  NbByte = 0, Sym = 0, Offset = 0 });  // SLLA         Shift Left Logical on Reg A
            dataList.Add(new InstrTable { StringValue = "SLAA",         OpCode = 0x0E,  NbByte = 0, Sym = 0, Offset = 0 });  // SLAA         Shift Left Arithmetic on Reg A (SLAA same as SLLA)
            dataList.Add(new InstrTable { StringValue = "JRNC @",       OpCode = 0x0F,  NbByte = 1, Sym = 2, Offset = 5 });  // JRNC symbol  Jump Relatif Not Carry
            dataList.Add(new InstrTable { StringValue = "RRCA",         OpCode = 0x10,  NbByte = 0, Sym = 0, Offset = 0 });  // RRCA         Rotate Right Logical Reg A through Carry  C -> b7 b6 b5 b4 b3 b2 b1 b0 -> C         
            dataList.Add(new InstrTable { StringValue = "RCF",          OpCode = 0x11,  NbByte = 0, Sym = 0, Offset = 0 });  // RCF          Reset Carry Flag C <- 0
            dataList.Add(new InstrTable { StringValue = "SCF",          OpCode = 0x12,  NbByte = 0, Sym = 0, Offset = 0 });  // SCF          Set Carry Flag C <- 1
            dataList.Add(new InstrTable { StringValue = "DECXL",        OpCode = 0x13,  NbByte = 0, Sym = 0, Offset = 0 });  // DECXL        Decrement XL (E updated)
            dataList.Add(new InstrTable { StringValue = "RRC @",        OpCode = 0x14,  NbByte = 2, Sym = 1, Offset = 4 });  // RRC symbol   Rotate Right Logical Address location through Carry  C -> b7 b6 b5 b4 b3 b2 b1 b0 -> C
            dataList.Add(new InstrTable { StringValue = "SRL @",        OpCode = 0x15,  NbByte = 2, Sym = 1, Offset = 4 });  // SRL symbol   Shift Right Logical on address  0 -> b7 b6 b5 b4 b3 b2 b1 b0 -> C
            dataList.Add(new InstrTable { StringValue = "ADCA 0x****",  OpCode = 0x28,  NbByte = 2, Sym = 0, Offset = 7 });  // ADCA 0x****  Add Byte from Address into REG A + C, Carry update
            dataList.Add(new InstrTable { StringValue = "ADCA @",       OpCode = 0x28,  NbByte = 2, Sym = 1, Offset = 5 });  // ADCA symbol
            dataList.Add(new InstrTable { StringValue = "ADDA 0x****",  OpCode = 0x29,  NbByte = 2, Sym = 0, Offset = 7 });  // ADDA 0x****  Add Byte from Address into REG A Carry update
            dataList.Add(new InstrTable { StringValue = "ADDA @",       OpCode = 0x29,  NbByte = 2, Sym = 1, Offset = 5 });  // ADDA symbol
            dataList.Add(new InstrTable { StringValue = "LDA 0x****",   OpCode = 0x2A,  NbByte = 2, Sym = 0, Offset = 6 });  // LDA 0x****   Load Byte from Address into REG A
            dataList.Add(new InstrTable { StringValue = "LDA @",        OpCode = 0x2A,  NbByte = 2, Sym = 1, Offset = 4 });  // LDA symboL
            dataList.Add(new InstrTable { StringValue = "JNE 0x****",   OpCode = 0x2B,  NbByte = 2, Sym = 0, Offset = 6 });  // JNE 0x****   JUMP IF NOT EQUAL (E=0)
            dataList.Add(new InstrTable { StringValue = "JNE @",        OpCode = 0x2B,  NbByte = 2, Sym = 1, Offset = 4 });  // JNE symbol
            dataList.Add(new InstrTable { StringValue = "JEQ 0x****",   OpCode = 0x2C,  NbByte = 2, Sym = 0, Offset = 6 });  // JEQ 0x****   JUMP IF EQUAL (E=1)
            dataList.Add(new InstrTable { StringValue = "JEQ",          OpCode = 0x2C,  NbByte = 2, Sym = 1, Offset = 4 });  // JEQ symbol
            dataList.Add(new InstrTable { StringValue = "CMPA #0x**",   OpCode = 0x2D,  NbByte = 1, Sym = 0, Offset = 8 });  // CMPA #0x**   COMPARE REGISTER A WITH IMMEDIATE BYTE, E=1 equal, E=0 different
            dataList.Add(new InstrTable { StringValue = "ADCA #0x**",   OpCode = 0x2E,  NbByte = 1, Sym = 0, Offset = 8 });  // ADCA #0x**   REG A = REG A + IMMEDIATE BYTE + CARRY (C), Carry C Updated
            dataList.Add(new InstrTable { StringValue = "ADDA #0x**",   OpCode = 0x2F,  NbByte = 1, Sym = 0, Offset = 8 });  // ADDA #0x**   ADD IMMEDIATE BYTE VALUE TO REGISTER A  C UPDATED
            dataList.Add(new InstrTable { StringValue = "LDA #0x**",    OpCode = 0x30,  NbByte = 1, Sym = 0, Offset = 7 });  // LDA #0x**    LOAD IMMEDIATE VALUE IN REGISTER A
            dataList.Add(new InstrTable { StringValue = "STA 0x****",   OpCode = 0x31,  NbByte = 2, Sym = 0, Offset = 6 });  // STA 0x****   STORE REG.A TO ADDRESSE
            dataList.Add(new InstrTable { StringValue = "STA @",        OpCode = 0x31,  NbByte = 2, Sym = 1, Offset = 4 });  // STA symbol
            dataList.Add(new InstrTable { StringValue = "JMP 0x****",   OpCode = 0x32,  NbByte = 2, Sym = 0, Offset = 6 });  // JMP 0x****   JUMP INCONDITIONAL TO ADDRESS
            dataList.Add(new InstrTable { StringValue = "JMP",          OpCode = 0x32,  NbByte = 2, Sym = 1, Offset = 4 });  // JMP symbol
            dataList.Add(new InstrTable { StringValue = "ANDA #0x**",   OpCode = 0x33,  NbByte = 1, Sym = 0, Offset = 8 });  // ANDA #0x**   REGISTER A AND LOGICAL WITH IMMEDIATE BYTE
            dataList.Add(new InstrTable { StringValue = "ORA #0x**",    OpCode = 0x34,  NbByte = 1, Sym = 0, Offset = 7 });  // ORA #0x**    LOGICAL OR BETWEEN REG A AND IMMEDIATE BYTE
            dataList.Add(new InstrTable { StringValue = "XORA #0x**",   OpCode = 0x35,  NbByte = 1, Sym = 0, Offset = 8 });  // XORA #0x**   EXCLUSIVE OR BETWEEN REG A AND IMMEDIATE BYTE
            dataList.Add(new InstrTable { StringValue = "NOTA",         OpCode = 0x36,  NbByte = 0, Sym = 0, Offset = 0 });  // NOTA         LOGIC NOT ON REG A
            dataList.Add(new InstrTable { StringValue = "INCA",         OpCode = 0x37,  NbByte = 0, Sym = 0, Offset = 0 });  // INCA         INCREMENT REGISTER A, E update, C not updated
            dataList.Add(new InstrTable { StringValue = "LDX #0x****",  OpCode = 0x38,  NbByte = 2, Sym = 0, Offset = 7 });  // LDX #0x****  Load X Register with 16 bits immediate value
            dataList.Add(new InstrTable { StringValue = "INCX",         OpCode = 0x39,  NbByte = 0, Sym = 0, Offset = 0 });  // INCX         Increment Register X,  Carry Not Updated

            UInt32 LineCounter;
            int iFirstCharacterIndex;
            int iPosComment;
            string sNibble;
            int iMsq = 0;
            int iLsq = 0;
            int[] iOpData = new int[5]; // Creates an array of 5 integers

            // Make a two pass assembler.  First pass to gather symbols tables with addresses and a second pass for code assembly.

            for (int iPass = 1; iPass <= 2; iPass++)
            {
                Console.Write("Pass=" + iPass + "\n");
                LineCounter = 0;    // Input source file line number beeing processed
                iAddress = 0;
                iErrorNumber = 0;
                using (StreamReader inputFile = File.OpenText(fullPath))
                using (StreamWriter lstFile = File.CreateText(Path.Combine(sRepositoryPath, baseFileName + ".lst")))
                {
                    string sLine = "";
                    while (!inputFile.EndOfStream)
                    {
                        LineCounter++;
                        sLine = inputFile.ReadLine();
                        iFirstCharacterIndex = FindFirstNonSpaceCharacter(sLine);
                        iPosComment = sLine.IndexOf(';');   // Locate where the comment begin

                        // Empty line ?
                        if (iFirstCharacterIndex == -1)    
                        {
                            if (iPass == 2)     // Output only in PASS 2
                            {
                                Console.WriteLine("");
                                lstFile.WriteLine("");
                            }
                        }

                        // Begin with ";"
                        else if (sLine.Substring(0, 1) == ";")  
                        {
                            if (iPass == 2)     // Output only in PASS 2
                            {
                                sLine = sLine.PadLeft(sLine.Length + iAssembledMnemonicPosition);

                                Console.WriteLine(sLine);
                                lstFile.WriteLine(sLine);
                            }
                        }

                        // Only a comment line ?
                        else if (iFirstCharacterIndex == iPosComment)   
                        {
                            if (iPass == 2)     // Output only in PASS 2
                            {
                                Console.Write(new string(' ', iAssembledMnemonicPosition));
                                lstFile.Write(new string(' ', iAssembledMnemonicPosition));
                                Console.WriteLine(sLine);
                                lstFile.WriteLine(sLine);
                            }
                        }

                        // Process the line
                        else
                        {   
                            // Line start with a symbol?
                            // if (iFirstCharacterIndex == 0)
                            {
                                int iSpaceIndex = sLine.IndexOf(' ');   // Find the index of the first space character
                                                                       
                                string sSymbol = sLine.Substring(0, iSpaceIndex);   // Extract the substring from the start of the space character

                                if (sSymbol != "")  // Only if non empty symbol
                                {
                                    // Symbol directory check and update only possible in PASS 1
                                    if (iPass == 1)
                                    {
                                        if (!symbolTable.ContainsKey(sSymbol))              // only if symbol does not exist
                                        {
                                            {
                                                symbolTable[sSymbol] = new SymbolTableEntry { Symbol = sSymbol, Address = iAddress };
                                            }
                                        }
                                    }
                                }
                                // Check if there is a mnemonic following
                                int iNextNonSpaceIndex = FindNextNonSpaceCharacter(sLine, iSpaceIndex);
                                // Reposition the iFirstCharacterIndex to be the begin of the mnemonic
                                iFirstCharacterIndex = iNextNonSpaceIndex;
                            }

                            // Search in mnemonic table

                            bool bFound = false;
                            int iIndexTable = 0;    // start at first location

                            foreach (InstrTable data in dataList)
                            {
                                int iCodeLength = data.StringValue.Length;
                                int iCharPointer = 0;
                                bool bIdentical = true;

                                while ((iCharPointer < iCodeLength) && bIdentical)
                                {
                                    char cCode = data.StringValue[iCharPointer];
                                    if ((cCode != '*') && (cCode != '@'))   // Compare only if not one of these symbol
                                    {
                                        if (iCharPointer > (sLine.Length - iFirstCharacterIndex - 1))
                                        {
                                            bIdentical = false;
                                        }
                                        else if (cCode != sLine[iCharPointer + iFirstCharacterIndex])
                                        {
                                            bIdentical = false;
                                        }
                                    }
                                    if (cCode == '@')   // symbol begin is expected here
                                    {
                                        if (sLine[iCharPointer + iFirstCharacterIndex] == '#')  // if immediate then it's not a symbol
                                        {
                                            bIdentical = false;
                                        }
                                    }
                                    iCharPointer++;
                                }

                                if (bIdentical)
                                {
                                    bFound = true;
                                    break;
                                }
                                else
                                {
                                    iIndexTable++;
                                }
                            }

                            if (bFound)
                            {
                                int iOffset = 0;
                                if (iIndexTable == 0)   // ORG
                                {
                                    iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;
                                    iAddress = int.Parse(sLine.Substring(iOffset, 4), System.Globalization.NumberStyles.HexNumber);
                                    if (iPass == 2)
                                    {
                                       Console.Write(new string(' ', iAssembledMnemonicPosition));
                                       lstFile.Write(new string(' ', iAssembledMnemonicPosition));

                                       Console.WriteLine(sLine);
                                       lstFile.WriteLine(sLine);
                                    }
                                }
                                else if (iIndexTable == 1)   // DB
                                {
                                    iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;
                                    sNibble = sLine.Substring(iOffset, 1);
                                    getNibble(sNibble, ref iMsq, ref iErrorNumber);
                                    sNibble = sLine.Substring(iOffset + 1, 1);
                                    getNibble(sNibble, ref iLsq, ref iErrorNumber);
                                    iOpData[0] = 16 * iMsq + iLsq;
                                }
                                else if (iIndexTable == 2)   // EQU
                                {
                                    int iSpaceIndex = sLine.IndexOf(' ');  // Find first space
                                    string sSymbol = sLine.Substring(0, iSpaceIndex);
                                    iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;
                                    int iSymbolAddress = int.Parse(sLine.Substring(iOffset, 4), System.Globalization.NumberStyles.HexNumber);
                                    symbolTable[sSymbol].Address = iSymbolAddress; // Update the address

                                    if (iPass == 2)
                                    {
                                        Console.Write(new string(' ', iAssembledMnemonicPosition));
                                        lstFile.Write(new string(' ', iAssembledMnemonicPosition));
                                        Console.WriteLine(sLine);
                                        lstFile.WriteLine(sLine);
                                    }
                                }
                                else    // Mnemonic to assemble
                                {
                                    int iSim = dataList[iIndexTable].Sym;
                                    
                                    // Hexadecimal address directly specifyed after the mnemonic ?
                                    if (iSim == 0)
                                    {
                                        switch (dataList[iIndexTable].NbByte)   // How many byte follow
                                        {
                                            case 0:     // No byte following, we only have the opcode
                                                iOpData[0] = dataList[iIndexTable].OpCode;
                                                break;
                                            case 1:     // One byte after opcode
                                                iOpData[0] = dataList[iIndexTable].OpCode;
                                                iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;
                                                sNibble = sLine.Substring(iOffset, 1);
                                                getNibble(sNibble, ref iMsq, ref iErrorNumber);
                                                sNibble = sLine.Substring(iOffset + 1, 1);
                                                getNibble(sNibble, ref iLsq, ref iErrorNumber);
                                                iOpData[1] = 16 * iMsq + iLsq;
                                                break;
                                            case 2:     // Two bytes after opcode
                                                iOpData[0] = dataList[iIndexTable].OpCode;
                                                iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;
                                                sNibble = sLine.Substring(iOffset, 1);
                                                getNibble(sNibble, ref iMsq, ref iErrorNumber);
                                                sNibble = sLine.Substring(iOffset + 1, 1);
                                                getNibble(sNibble, ref iLsq, ref iErrorNumber);
                                                iOpData[1] = 16 * iMsq + iLsq;
                                                sNibble = sLine.Substring(iOffset + 2, 1);
                                                getNibble(sNibble, ref iMsq, ref iErrorNumber);
                                                sNibble = sLine.Substring(iOffset + 3, 1);
                                                getNibble(sNibble, ref iLsq, ref iErrorNumber);
                                                iOpData[2] = 16 * iMsq + iLsq;
                                                break;
                                            default:
                                                // In case the OP code decoding is not implemented
                                                string sOpNotImplemented = $"{new string(' ', 7)}****** NOT IMPLEMENTED BYTE SIZE  ******* {sLine.Substring(0, Math.Min(13, sLine.Length))}";
                                                Console.WriteLine(sOpNotImplemented);
                                                lstFile.WriteLine(sOpNotImplemented);
                                                iErrorNumber++;
                                                break;
                                        }
                                    }
                                    // Symbolic address next to mnemonic ?
                                    else if (iSim == 1) 
                                    {
                                        if (iPass == 2)
                                        {

                                            // Read the symbol
                                            // Compute the offset to the first character of the symbol
                                            iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;
                                            
                                            // Find the next space or the end of the string
                                            int endIndex = sLine.IndexOf(' ', iOffset);

                                            // Extract the symbol
                                            string sSymbol = (endIndex == -1) ? sLine.Substring(iOffset) : sLine.Substring(iOffset, endIndex - iOffset);

                                            // Now, to find the address of the symbol:
                                            if (symbolTable.ContainsKey(sSymbol))
                                            {
                                                int symbolAddress = symbolTable[sSymbol].Address;

                                                // Split the address into MSB (Most Significant Byte) and LSB (Least Significant Byte)
                                                byte msb = (byte)((symbolAddress >> 8) & 0xFF);  // Shift right by 8 bits and mask to get the MSB
                                                byte lsb = (byte)(symbolAddress & 0xFF);         // Mask to get the LSB

                                                // Fill in the operation data array
                                                iOpData[0] = dataList[iIndexTable].OpCode;
                                                iOpData[1] = msb;  // Most Significant Byte in iOpData[1]
                                                iOpData[2] = lsb;  // Least Significant Byte in iOpData[2]
                                            }
                                            // Could not find the symbol in the table
                                            else
                                            {
                                                string sLineNumber = iAddress.ToString("X");
                                                Console.Write(sLineNumber);
                                                lstFile.WriteLine(sLineNumber);

                                                string sErrorMsg = $"{new string(' ', 7)}****** ERROR @ line {LineCounter} address {iAddress:X4}, Can't find symbol  " + sSymbol + " ******";

                                                Console.WriteLine(sLine);
                                                Console.WriteLine(sErrorMsg);

                                                lstFile.WriteLine(sLine);
                                                lstFile.WriteLine(sErrorMsg);

                                                iErrorNumber++;
                                                iAddress++;
                                            }
                                        }


                                    }
                                    // Relative address jump +-127 to be computed from the symbol next to the mnemonic
                                    else if (iSim == 2)
                                    {
                                        if (iPass == 2)
                                        {
                                            // Read the symbol
                                            // Compute the offset to the first character of the symbol
                                            iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;

                                            // Find the next space or the end of the string
                                            int endIndex = sLine.IndexOf(' ', iOffset);

                                            // Extract the symbol
                                            string sSymbol = (endIndex == -1) ? sLine.Substring(iOffset) : sLine.Substring(iOffset, endIndex - iOffset);

                                            // Now, to find the address of the symbol:
                                            if (symbolTable.ContainsKey(sSymbol))
                                            {
                                                int symbolAddress = symbolTable[sSymbol].Address;

                                                // Compute the difference beetween symbol address and next operand address to be exectued
                                                int iDiff = symbolAddress - (iAddress + 2);

                                                // Check if outside of addressing range
                                                if((iDiff < -128) || (iDiff > 127))
                                                {
                                                    string sLineNumber = iAddress.ToString("X");
                                                    Console.Write(sLineNumber);
                                                    lstFile.WriteLine(sLineNumber);

                                                    string sErrorMsg = $"{new string(' ', 7)}****** ERROR @ line {LineCounter} address 0x{iAddress:X4}, Relative address {iDiff} ouside -128 to +127 range ******";
                                                    Console.WriteLine(sLine);
                                                    Console.WriteLine(sErrorMsg);

                                                    lstFile.WriteLine(sLine);
                                                    lstFile.WriteLine(sErrorMsg);

                                                    iErrorNumber++;
                                                    iAddress++;
                                                }

                                                // Fill in the operation data array
                                                iOpData[0] = dataList[iIndexTable].OpCode;
                                                byte bRelAddress = (byte)(iDiff & 0xFF);
                                                iOpData[1] = bRelAddress;
                                            }
                                            // Could not find the symbol in the table
                                            else
                                            {
                                                string sLineNumber = iAddress.ToString("X");
                                                Console.Write(sLineNumber);
                                                lstFile.WriteLine(sLineNumber);

                                                string sErrorMsg = $"{new string(' ', 7)}****** ERROR @ line {LineCounter} address 0x{iAddress:X4}, Can't find symbol  " + sSymbol + " ******";

                                                Console.WriteLine(sLine);
                                                Console.WriteLine(sErrorMsg);

                                                lstFile.WriteLine(sLine);
                                                lstFile.WriteLine(sErrorMsg);

                                                iErrorNumber++;
                                                iAddress++;
                                            }
                                        }


                                    }
                                }

                                if ((iIndexTable != 0) & (iIndexTable != 2))  // Only if not an ORG and not EQU
                                {
                                    if (iPass == 2)
                                    {
                                        // Line number
                                        string sLineNumber = iAddress.ToString("X");
                                        Console.Write(sLineNumber);
                                        lstFile.Write(sLineNumber);

                                        // Assembled result
                                        string sAssembledCode = "";
                                        for (int i = 0; i < dataList[iIndexTable].NbByte + 1; i++)
                                        {
                                            sAssembledCode = sAssembledCode + " " + iOpData[i].ToString("X2");
                                        }
                                        string sAllignedAssembledCode = "";
                                        sAllignedAssembledCode = sAssembledCode.PadRight(iTotalAssembledFieldWidth);
                                        Console.Write(sAllignedAssembledCode);
                                        lstFile.Write(sAllignedAssembledCode);

                                        // Full line with end of line
                                        Console.WriteLine(sLine);
                                        lstFile.WriteLine(sLine);
                                    }

                                    // Store in EEPROM number of bytes and update line number accordingly
                                    for (int i = 0; i < dataList[iIndexTable].NbByte + 1; i++)
                                    {
                                        aEeprom[iAddress - iAddressEepromBegin] = iOpData[i];
                                        iAddress = iAddress + 1;
                                    }

                                }
                            }
                            else
                            {   // instruction not found
                                string sLineNumber = iAddress.ToString("X") + " ";  // Append a spaceafter line number
                                Console.Write(sLineNumber);
                                lstFile.WriteLine(sLineNumber);

                                string sErrorMsg = $"{new string(' ', 7)}****** ERROR on line {LineCounter} address 0x{iAddress:X4}, Can't find mnemonic {sLine.Substring(0, Math.Min(13, sLine.Length))} ******";

                                Console.WriteLine(sLine);
                                Console.WriteLine(sErrorMsg);

                                lstFile.WriteLine(sLine);
                                lstFile.WriteLine(sErrorMsg);

                                iErrorNumber++;
                                iAddress++;
                            }
                        }

                        // If stop on error is enabled and found an error then stop
                       
                        if((iPass == 2) && bStopOnError && (iErrorNumber >= 1))
                        {
                            break;
                        }
                    } // end of file reading

                    if (iPass == 2)
                    {
                        // Print symbol table for debugging or verification
                        //PrintSymbolTable();
                        //static void PrintSymbolTable()
                        {
                            sTemp = "Symbol Table:";
                            Console.WriteLine(sTemp);
                            lstFile.WriteLine(sTemp);

                            int symbolWidth = 20; // Fixed width for symbol name

                            foreach (var entry in symbolTable)
                            {
                                // Truncate or pad the symbol name to exactly `symbolWidth` characters
                                string symbolName = entry.Key.Length > symbolWidth
                                    ? entry.Key.Substring(0, symbolWidth)  // Truncate if too long
                                    : entry.Key.PadRight(symbolWidth);    // Pad with spaces if too short

                                // Format output with the symbol and its value (hex)
                                sTemp = $"{symbolName}{entry.Value.Address:X4}";
                                Console.WriteLine(sTemp);
                                lstFile.WriteLine(sTemp);
                            }
                        }

                        sTemp = "Assembly complete";
                        Console.WriteLine(sTemp);
                        lstFile.WriteLine(sTemp);

                        string sName_msb = Path.Combine(sRepositoryPath, baseFileName + ".bin");
                        using (BinaryWriter msbFile = new BinaryWriter(new FileStream(sName_msb, FileMode.Create)))
                        {
                            foreach (byte value in aEeprom)
                            {
                                msbFile.Write(value);
                            }
                        }

                        Console.WriteLine("Data written to file successfully.");
                    }

                }

                if( iPass==1 )
                {
                    iErrorNumberPass1 = iErrorNumber;
                }
                else
                {
                    iErrorNumberPass2 = iErrorNumber;
                    sTemp = "Number of errors in Pass 1 = " + iErrorNumberPass1;
                    Console.WriteLine(sTemp);

                    sTemp = "Number of errors in Pass 2 = " + iErrorNumberPass2;
                    Console.WriteLine(sTemp);
                }

                
            }

            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();

        }

        static int FindFirstNonSpaceCharacter(string input)
        {
            for (int i = 0; i < input.Length; i++)
            {
                if (input[i] != ' ')
                {
                    return i;
                }
            }

            // Return -1 if no non-space character is found
            return -1;
        }

        static int FindColonCharacter(string input) // Find colon character not in comment area
        {
            for (int i = 0; i < input.Length; i++)
            {
                if (input[i] != ';')    // Begin of comment area then
                {
                    return -1;          // Return we did not found the colon character
                }
                else if (input[i] == ':')
                {
                    return i;           // Found a colon character, return position
                }
            }

            // Return -1 if colon character not found
            return -1;
        }

    }
}
