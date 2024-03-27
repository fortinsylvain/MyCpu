// Homebrew MyCPU assembler program
// Author: Sylvain Fortin
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
        public int Offset { get; set; }
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
            int iAddress = 0;
            int iTotalAssembledFieldWidth = 12; // number of character allowed to print assembled bytes.
            int iAssembledMnemonicPosition = 4 + iTotalAssembledFieldWidth; // 4 correspond to number of characters for the address

            List<InstrTable> dataList = new List<InstrTable>();
            // OpCode : Byte value used to code each instruction
            // NbByte : Number of bytes following the OP code byte
            // Offset : Character position where the hex value start.
            // Presently only hexadecimal values are supported, 8 and 16 bits only.
            dataList.Add(new InstrTable { StringValue = "ORG/****H", OpCode = 0, NbByte = 0, Offset = 0 });  // 
            dataList.Add(new InstrTable { StringValue = "DB **H", OpCode = 0, NbByte = 0, Offset = 3 });  // Define Byte in EEPROM Memory
            dataList.Add(new InstrTable { StringValue = "JSR ****H", OpCode = 0x06, NbByte = 2, Offset = 4 });  // JSR ****H    Jump to SubRoutine
            dataList.Add(new InstrTable { StringValue = "RTS", OpCode = 0x07, NbByte = 0, Offset = 0 });  // RTS          ReTurn from Subroutine
            dataList.Add(new InstrTable { StringValue = "STOP", OpCode = 0x08, NbByte = 0, Offset = 0 });  // STOP         STOP Executing
            dataList.Add(new InstrTable { StringValue = "NOP", OpCode = 0x09, NbByte = 0, Offset = 0 });  // NOP          No Operation
            dataList.Add(new InstrTable { StringValue = "LDA (X)", OpCode = 0x0A, NbByte = 0, Offset = 0 });  // LDA (X)      Load Reg A Indexed
            dataList.Add(new InstrTable { StringValue = "STA (X)", OpCode = 0x0B, NbByte = 0, Offset = 0 });  // STA (X)      Store Reg A Indexed
            dataList.Add(new InstrTable { StringValue = "JRA **H", OpCode = 0x0C, NbByte = 1, Offset = 4 });  // JRA **H      Unconditional relative jump
            dataList.Add(new InstrTable { StringValue = "SRLA", OpCode = 0x0D, NbByte = 0, Offset = 0 });  // SRLA         Shift Right Logical on Reg A
            dataList.Add(new InstrTable { StringValue = "SLLA", OpCode = 0x0E, NbByte = 0, Offset = 0 });  // SLLA         Shift Left Logical on Reg A
            dataList.Add(new InstrTable { StringValue = "SLAA", OpCode = 0x0E, NbByte = 0, Offset = 0 });  // SLAA         Shift Left Arithmetic on Reg A (SLAA same as SLLA)
            dataList.Add(new InstrTable { StringValue = "ADDA ****H", OpCode = 0x29, NbByte = 2, Offset = 5 });  // ADDA ****H   Add Byte from Address into REG A Carry update
            dataList.Add(new InstrTable { StringValue = "LDA ****H", OpCode = 0x2A, NbByte = 2, Offset = 4 });  // LDA ****H    Load Byte from Address into REG A
            dataList.Add(new InstrTable { StringValue = "JNE ****H", OpCode = 0x2B, NbByte = 2, Offset = 4 });  // JNE ****H    JUMP IF NOT EQUAL (E=0)
            dataList.Add(new InstrTable { StringValue = "JEQ ****H", OpCode = 0x2C, NbByte = 2, Offset = 4 });  // JEQ ****H    JUMP IF EQUAL (E=1)
            dataList.Add(new InstrTable { StringValue = "CMPA #**H", OpCode = 0x2D, NbByte = 1, Offset = 6 });  // CMPA #**H    COMPARE REGISTER A WITH IMMEDIATE BYTE, E=1 equal, E=0 different
            dataList.Add(new InstrTable { StringValue = "ADCA #**H", OpCode = 0x2E, NbByte = 1, Offset = 6 });  // ADCA #**H    REG A = REG A + IMMEDIATE BYTE + CARRY (C), Carry C Updated
            dataList.Add(new InstrTable { StringValue = "ADDA #**H", OpCode = 0x2F, NbByte = 1, Offset = 6 });  // ADDA #**H    ADD IMMEDIATE BYTE VALUE TO REGISTER A  C UPDATED
            dataList.Add(new InstrTable { StringValue = "LDA #**H", OpCode = 0x30, NbByte = 1, Offset = 5 });  // LDA #**H     LOAD IMMEDIATE VALUE IN REGISTER A
            dataList.Add(new InstrTable { StringValue = "STA ****H", OpCode = 0x31, NbByte = 2, Offset = 4 });  // STA ****H    STORE REG.A TO ADDRESSE
            dataList.Add(new InstrTable { StringValue = "JMP ****H", OpCode = 0x32, NbByte = 2, Offset = 4 });  // JMP ****H    JUMP INCONDITIONAL TO ADDRESS
            dataList.Add(new InstrTable { StringValue = "ANDA #**H", OpCode = 0x33, NbByte = 1, Offset = 6 });  // ANDA #**H    REGISTER A AND LOGICAL WITH IMMEDIATE BYTE
            dataList.Add(new InstrTable { StringValue = "ORA #**H", OpCode = 0x34, NbByte = 1, Offset = 5 });  // ORA #**H     LOGICAL OR BETWEEN REG A AND IMMEDIATE BYTE
            dataList.Add(new InstrTable { StringValue = "XORA #**H", OpCode = 0x35, NbByte = 1, Offset = 6 });  // XORA #**H    EXCLUSIVE OR BETWEEN REG A AND IMMEDIATE BYTE
            dataList.Add(new InstrTable { StringValue = "NOTA", OpCode = 0x36, NbByte = 0, Offset = 0 });  // NOTA         LOGIC NOT ON REG A
            dataList.Add(new InstrTable { StringValue = "INCA", OpCode = 0x37, NbByte = 0, Offset = 0 });  // OP.37 INCA   INCREMENT REGISTER A, NO UPDATE ON CARRY
            dataList.Add(new InstrTable { StringValue = "LDX #****H", OpCode = 0x38, NbByte = 2, Offset = 5 });  // LDX #****H   Load X Register with 16 bits immediate value
            dataList.Add(new InstrTable { StringValue = "INCX", OpCode = 0x39, NbByte = 0, Offset = 0 });  // INCX         Increment Register X,  Carry Not Updated

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
                iAddress = 0;
                using (StreamReader inputFile = File.OpenText(fullPath))
                using (StreamWriter lstFile = File.CreateText(Path.Combine(sRepositoryPath, baseFileName + ".lst")))
                {
                    string sLine = "";
                    while (!inputFile.EndOfStream)
                    {
                        sLine = inputFile.ReadLine();
                        iFirstCharacterIndex = FindFirstNonSpaceCharacter(sLine);
                        iPosComment = sLine.IndexOf(';');   // Locate where the comment begin

                        if (iFirstCharacterIndex == -1)    // Empty line ?
                        {
                            if (iPass == 2)     // Output only in PASS 2
                            {
                                Console.WriteLine("");
                                lstFile.WriteLine("");
                            }
                        }
                        else if (sLine.Substring(0, 1) == ";")  // Begin with ";"
                        {
                            if (iPass == 2)     // Output only in PASS 2
                            {
                                Console.WriteLine(sLine);
                                lstFile.WriteLine(sLine);
                            }
                        }
                        else if (iFirstCharacterIndex == iPosComment)   // Only a comment line
                        {
                            if (iPass == 2)     // Output only in PASS 2
                            {
                                Console.Write(new string(' ', iAssembledMnemonicPosition));
                                lstFile.Write(new string(' ', iAssembledMnemonicPosition));
                                Console.WriteLine(sLine);
                                lstFile.WriteLine(sLine);
                            }
                        }
                        else // Process the line
                        {
                            bool bStartWithSymbol = false;
                            if (iFirstCharacterIndex == 0) // Verify if line start with a symbol?
                            {
                                int iSpaceIndex = sLine.IndexOf(' ');   // Find the index of the first space character

                                string sSymbol = sLine.Substring(0, iSpaceIndex);   // Extract the substring from the start of the space character
                                if (!symbolTable.ContainsKey(sSymbol))              // only if symbol does not exist
                                {
                                    if (iPass == 1)                                 // Symbol directory updated only in PASS 1
                                    {
                                        symbolTable[sSymbol] = new SymbolTableEntry { Symbol = sSymbol, Address = iAddress };
                                    }
                                }
                                // Check if there is a mnemonic following
                                int iNextNonSpaceIndex = FindNextNonSpaceCharacter(sLine, iSpaceIndex);
                                // Reposition the iFirstCharacterIndex to be the begin of the mnemonic
                                iFirstCharacterIndex = iNextNonSpaceIndex;
                            }

                            // Find in table the mnemonic
                            bool bFound = false;
                            int iIndexTable = 0;    // start at first location
                                                    //while ((iIndexTable < iTblNumberOfElement) && !bFound)
                            foreach (InstrTable data in dataList)
                            {
                                int iCodeLength = data.StringValue.Length;
                                int iCharPointer = 0;
                                bool bIdentical = true;

                                while ((iCharPointer < iCodeLength) && bIdentical)
                                {
                                    char cCode = data.StringValue[iCharPointer];
                                    if (cCode != '*')   // Compare only if not and an asterix
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
                                    iAddress = int.Parse(sLine.Substring(iFirstCharacterIndex + 4, 4), System.Globalization.NumberStyles.HexNumber);

                                    if (iPass == 2)
                                    {
                                        Console.Write(new string(' ', iAssembledMnemonicPosition));
                                        lstFile.Write(new string(' ', iAssembledMnemonicPosition));

                                        Console.WriteLine(sLine);
                                        lstFile.WriteLine(sLine);
                                    }
                                }
                                if (iIndexTable == 1)   // DB
                                {
                                    iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;
                                    sNibble = sLine.Substring(iOffset, 1);
                                    getNibble(sNibble, ref iMsq, ref iErrorNumber);
                                    sNibble = sLine.Substring(iOffset + 1, 1);
                                    getNibble(sNibble, ref iLsq, ref iErrorNumber);
                                    iOpData[0] = 16 * iMsq + iLsq;
                                }
                                else    // Mnemonic to assemble
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

                                if (iIndexTable != 0)  // Only if not an ORG
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
                                string sLineNumber = iAddress.ToString("X");   // Line number
                                Console.Write(sLineNumber);
                                lstFile.WriteLine(sLineNumber);

                                string sErrorMsg = $"{new string(' ', 7)}****** ERROR @ LINE {iAddress:X4}, CANT FIND MNEMONIC {sLine.Substring(0, Math.Min(13, sLine.Length))} ******";

                                Console.WriteLine(sLine);
                                Console.WriteLine(sErrorMsg);

                                lstFile.WriteLine(sLine);
                                lstFile.WriteLine(sErrorMsg);

                                iErrorNumber++;
                                iAddress = iAddress + 1;
                            }
                        }

                    } // end of file reading

                    if (iPass == 2)     // Print Symbol Table
                    {
                        // Print symbol table for debugging or verification
                        //PrintSymbolTable();
                        //static void PrintSymbolTable()
                        {
                            sTemp = "Symbol Table:";
                            Console.WriteLine(sTemp);
                            lstFile.WriteLine(sTemp);
                            foreach (var entry in symbolTable)
                            {
                                //Console.WriteLine($"Symbol: {entry.Key}, Address: {entry.Value.Address}");
                                //string sSymbol = entry.Key;
                                sTemp = $"{entry.Key,-10}{entry.Value.Address:X4}";
                                //Console.WriteLine($"{entry.Key,-10}{entry.Value.Address:X4}");
                                Console.WriteLine(sTemp);
                                lstFile.WriteLine(sTemp);
                            }
                        }
                    }

                    if (iPass == 2)     // Output only in PASS 2
                    {
                        sTemp = "Assembly complete";
                        Console.WriteLine(sTemp);
                        lstFile.WriteLine(sTemp);
                        sTemp = "Number of errors = " + iErrorNumber;
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
