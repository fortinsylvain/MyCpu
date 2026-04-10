// Homebrew MyCPU assembler program
// Author: Sylvain Fortin  sylfortin71@hotmail.com
// Date: 3 jan 2026
// Documentation:
// This program is an assembler that converts MyCPU mnemonics into opcodes
// executable by the MyCPU micro-program.
// 
// The source file (with .asm extension) is passed as a command-line argument.
//
// Two output files are generated:
// - filename.lst : ASCII listing file containing the address, opcode, operands,
//                  and comments.
// - filename.bin : Binary file containing the assembled data to be programmed
//                  into the EEPROM.
//
// The EEPROM programmer used is the TL866II Plus from XGecu.

using Assembler;
using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace Assembler
{
    public enum OperandMode
    {
        Hex = 0,
        Symbol = 1,
        Relative = 2,
        Ascii = 3,
        Negative = 4
    }

    public class InstrTable
    {
        public string StringValue { get; set; }
        public int OpCode { get; set; }
        public int NbByte { get; set; }
        public OperandMode Sym { get; set; }
        public int Offset { get; set; }
        public Regex Regex { get; set; }
        public string Operation { get; set; }   // Formal behavior
        public string Flags { get; set; }       // Flags affected
        public string Desc { get; set; }        // Human readable

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

        static void Main(string[] args)
        {

            bool bPrintISA = false;
            string sFileName = "";

            // ---- Argument parsing ----
            foreach (var arg in args)
            {
                if (arg == "-i" || arg == "--isa")
                {
                    bPrintISA = true;
                }
                else
                {
                    sFileName = arg;
                }
            }
            
            var dataList = BuildInstructionTable();

            
            // If ISA requested → print and exit
            if (bPrintISA)
            {
                PrintInstructionTable(dataList);
                return;
            }
            

            /*
            if (string.IsNullOrEmpty(sFileName))
            {
                Console.WriteLine("Usage:");
                Console.WriteLine("  assembler <file.asm>");
                Console.WriteLine("  assembler -i        (print instruction set)");
                return;
            }
            */

            bool bStopOnError = true;
            string sTemp;
            symbolTable = new Dictionary<string, SymbolTableEntry>();

            Console.WriteLine("Homebrew assembler start");
            string sCurrentPath = "";
            string sRepositoryPath = "";

            // ---- Argument validation ----
            if (args.Length != 1)
            {
                Console.WriteLine("ERROR: Invalid number of arguments.");
                Console.WriteLine("Usage: assembler <sourcefile.asm>");
                Environment.Exit(1);
            }

            sFileName = args[0];
            if (args.Length != 1)   // No argument
            {
                sRepositoryPath = "C:\\Sylvain\\MyCPU\\opCodeAssembler\\examples";    // Fixed path for now
                sFileName = "fibonacy.asm"; // Replace with your desired file name
            }
            else
            {                       // With argument
                sCurrentPath = Directory.GetCurrentDirectory();
                sRepositoryPath = Path.Combine(sCurrentPath, "..\\..\\examples");           // Move up two level and go to examples
                //sRepositoryPath = Path.Combine(sCurrentPath, "..\\..\\..\\examples");           // Move up two level and go to examples

            }

            string baseFileName = Path.GetFileNameWithoutExtension(sFileName);
            string fileExtension = Path.GetExtension(sFileName);
            string fullPath = Path.Combine(sRepositoryPath, sFileName);

            //int iAddressEepromBegin = 0xE000;
            int iAddressEepromBegin = 0x8000;

            // Reserve space for one 2864 EEPROM
            // we have 12 bit address (A12-A0)
            //const int iEpromSize = 8192;
            const int iEpromSize = 32768; // 32K size for 28C256 EEPROM with 15 bit address (A14-A0)

            int[] aEeprom = new int[iEpromSize];
            bool[] aEepromUsed = new bool[iEpromSize];
            string[] aEepromOwner = new string[iEpromSize]; // optional but recommended
            Array.Clear(aEepromUsed, 0, iEpromSize);

            int iErrorNumber = 0;
            int iErrorNumberPass1 = 0;
            int iErrorNumberPass2 = 0;
            int iAddress = 0;
            int iTotalAssembledFieldWidth = 12; // number of character allowed to print assembled bytes.
            int iAssembledMnemonicPosition = 4 + iTotalAssembledFieldWidth; // 4 correspond to number of characters for the address

            //var dataList = BuildInstructionTable();
            CompileRegex(dataList);

            WriteInstructionTable(Path.Combine(sRepositoryPath, "instruction_table.txt"), dataList);
            WriteRegexTable(Path.Combine(sRepositoryPath, "regex_table.txt"), dataList);

            StreamReader inputFile;

            try
            {
                inputFile = File.OpenText(fullPath);
            }
            catch (DirectoryNotFoundException)
            {
                Console.WriteLine("ERROR: Could not find part of the path:");
                Console.WriteLine(fullPath);
                return;
            }
            catch (FileNotFoundException)
            {
                Console.WriteLine("ERROR: File not found:");
                Console.WriteLine(fullPath);
                return;
            }

            int iIndexTable;
            int iFirstCharacterIndex;
            string sLine = "";

            
            iFirstCharacterIndex = 9;
            //sLine = "         LDA (?b0,X)";
            //sLine = "         LDA (SP-1)";
            //iIndexTable = FindInstructionIndex(sLine, iFirstCharacterIndex, dataList);

            //InstrTable tst_instr = dataList[51];
            //sLine = "LDA (SP-1)";
            //bool bTest = tst_instr.Regex.IsMatch(sLine);


            UInt32 LineCounter;
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

                if (iPass == 2)
                {
                    Array.Clear(aEepromUsed, 0, aEepromUsed.Length);
                    Array.Clear(aEepromOwner, 0, aEepromOwner.Length);
                }

                using (inputFile = File.OpenText(fullPath))
                using (StreamWriter lstFile = File.CreateText(Path.Combine(sRepositoryPath, baseFileName + ".lst")))

                {
                    sLine = "";
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
                            iIndexTable = 0;    // start at first location

                            iIndexTable = FindInstructionIndex(sLine, iFirstCharacterIndex, dataList);
                            if (iIndexTable != -1)
                            {
                                bFound = true;
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
                                    OperandMode iSim = dataList[iIndexTable].Sym;

                                    // Hexadecimal address directly specifyed after the mnemonic ?
                                    if (iSim == OperandMode.Hex)
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
                                    else if (iSim == OperandMode.Symbol)
                                    {
                                        if (iPass == 2)
                                        {

                                            // Read the symbol
                                            // Compute the offset to the first character of the symbol
                                            iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;

                                            // Find the next space or the end of the string
                                            //int endIndex = sLine.IndexOf(' ', iOffset);

                                            // Extract the symbol
                                            //string sSymbol = (endIndex == -1) ? sLine.Substring(iOffset) : sLine.Substring(iOffset, endIndex - iOffset);

                                            // Extract the symbol
                                            int endIndex = sLine.Length;
                                            int spaceIndex = sLine.IndexOf(' ', iOffset);   // space mark end of symbol
                                            int commaIndex = sLine.IndexOf(',', iOffset);   // comma also mark end of symbol

                                            if (spaceIndex != -1 && spaceIndex < endIndex) endIndex = spaceIndex;
                                            if (commaIndex != -1 && commaIndex < endIndex) endIndex = commaIndex;

                                            string sSymbol = sLine.Substring(iOffset, endIndex - iOffset);

                                            // Extract base symbol without offset (+1 or -2)
                                            var baseSymbolMatch = Regex.Match(sSymbol, @"^([A-Za-z_?][A-Za-z0-9_]*)");
                                            if (!baseSymbolMatch.Success)
                                            {
                                                // Invalid symbol format - report error and exit
                                                string sErrorMsg =
                                                    $"{new string(' ', 7)}****** ERROR @ line {LineCounter} address 0x{iAddress:X4}, Invalid symbol format: {sSymbol} ******";

                                                Console.WriteLine(sLine);
                                                Console.WriteLine(sErrorMsg);

                                                lstFile.WriteLine(sLine);
                                                lstFile.WriteLine(sErrorMsg);

                                                iErrorNumber++;
                                                iAddress++;
                                                return;  // or continue depending on your loop structure
                                            }

                                            string baseSymbol = baseSymbolMatch.Groups[1].Value;

                                            // Check if base symbol exists in the table
                                            if (symbolTable.ContainsKey(baseSymbol))
                                            {
                                                // Parse full expression with offset (if any)
                                                if (ParseSymbolExpression(sSymbol, symbolTable, out int symbolAddress))
                                                {
                                                    iOpData[0] = dataList[iIndexTable].OpCode;

                                                    int iNbByte = dataList[iIndexTable].NbByte;
                                                    if (iNbByte == 2)
                                                    {
                                                        iOpData[1] = (symbolAddress >> 8) & 0xFF;
                                                        iOpData[2] = symbolAddress & 0xFF;
                                                    }
                                                    else
                                                    {
                                                        iOpData[1] = symbolAddress & 0xFF;
                                                    }
                                                }
                                                else
                                                {
                                                    string sErrorMsg =
                                                        $"{new string(' ', 7)}****** ERROR @ line {LineCounter} address 0x{iAddress:X4}, Can't resolve symbol {sSymbol} ******";

                                                    Console.WriteLine(sLine);
                                                    Console.WriteLine(sErrorMsg);

                                                    lstFile.WriteLine(sLine);
                                                    lstFile.WriteLine(sErrorMsg);

                                                    iErrorNumber++;
                                                }

                                            }
                                            else
                                            {
                                                // Base symbol not found in symbol table
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
                                    else if (iSim == OperandMode.Relative)
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
                                                if ((iDiff < -128) || (iDiff > 127))
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
                                    else if (iSim == OperandMode.Ascii)
                                    {

                                        // ---- PASS 1 : advance PC only ----
                                        if (iPass == 1)
                                        {
                                            int iOffsetStartStringDelimiter = dataList[iIndexTable].Offset + iFirstCharacterIndex;

                                            int firstQuote = sLine.IndexOf('"', iOffsetStartStringDelimiter);
                                            int lastQuote = sLine.LastIndexOf('"');

                                            if (firstQuote == -1 || lastQuote <= firstQuote)
                                            {
                                                iErrorNumber++;
                                                continue;
                                            }

                                            int length = lastQuote - firstQuote - 1;
                                            iAddress += length + 1;   // +1 for null terminator
                                        }


                                        if (iPass == 2)
                                        {
                                            int startAddress = iAddress;

                                            // Extract quoted string
                                            iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;

                                            int firstQuote = sLine.IndexOf('"', iOffset);
                                            int lastQuote = sLine.LastIndexOf('"');

                                            if (firstQuote == -1 || lastQuote <= firstQuote)
                                            {
                                                Console.WriteLine("****** ERROR: Missing or invalid ASCII string ******");
                                                lstFile.WriteLine("****** ERROR: Missing or invalid ASCII string ******");
                                                iErrorNumber++;
                                                continue;
                                            }

                                            string text = sLine.Substring(firstQuote + 1, lastQuote - firstQuote - 1);

                                            // Build byte array once
                                            byte[] bytes = new byte[text.Length + 1];
                                            for (int i = 0; i < text.Length; i++)
                                            {
                                                bytes[i] = (byte)text[i];
                                            }

                                            bytes[text.Length] = 0;   // NULL terminator

                                            // Emit bytes
                                            foreach (byte b in bytes)
                                            {
                                                //aEeprom[iAddress - iAddressEepromBegin] = b;
                                                if (CheckAndMarkAddress(iAddress, iAddressEepromBegin, aEepromUsed, aEepromOwner, sLine.Trim(), LineCounter, ref iErrorNumber))
                                                {
                                                    aEeprom[iAddress - iAddressEepromBegin] = b;
                                                }
                                                iAddress++;
                                            }

                                            WriteListingWithContinuation(startAddress, bytes, sLine, lstFile, toConsole: true);
                                        }

                                    }

                                    // Negative offset to compute next to the mnemonic
                                    if (iSim == OperandMode.Negative)
                                    {
                                        iOpData[0] = dataList[iIndexTable].OpCode;

                                        // Locate start of the numeric offset
                                        iOffset = dataList[iIndexTable].Offset + iFirstCharacterIndex;

                                        // Extract everything until ')'
                                        int endIndex = sLine.IndexOf(')', iOffset);
                                        if (endIndex < 0)
                                        {
                                            iErrorNumber++;
                                            return;
                                        }

                                        string sNumber = sLine.Substring(iOffset, endIndex - iOffset).Trim();

                                        int value;
                                        if (!int.TryParse(sNumber, out value))
                                        {
                                            iErrorNumber++;
                                            return;
                                        }

                                        // Validate 8-bit signed range
                                        if (value < -128 || value > 127)
                                        {
                                            Console.WriteLine("Offset out of range (-128..127)");
                                            iErrorNumber++;
                                            return;
                                        }

                                        // Store as 2's complement
                                        iOpData[1] = (byte)((~value + 1) & 0xFF);


                                        /*
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
                                        // Compute the negative value in 2 complement form
                                        iOpData[1] = (byte)((~iOpData[1] + 1) & 0xFF);
                                        */
                                    }


                                }

                                //if ((iIndexTable != 0) & (iIndexTable != 2))  // Only if not an ORG and not EQU
                                if ((iIndexTable != 0) && (iIndexTable != 2) && dataList[iIndexTable].Sym != OperandMode.Ascii)
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
                                        //aEeprom[iAddress - iAddressEepromBegin] = iOpData[i];
                                        if (CheckAndMarkAddress(iAddress, iAddressEepromBegin, aEepromUsed, aEepromOwner, sLine.Trim(), LineCounter, ref iErrorNumber))
                                        {
                                            aEeprom[iAddress - iAddressEepromBegin] = iOpData[i];
                                        }
                                        iAddress = iAddress + 1;
                                    }

                                }

                            }
                            else
                            {   // instruction not found
                                string sLineNumber = iAddress.ToString("X") + " ";  // Append a spaceafter line number
                                Console.Write(sLineNumber);
                                lstFile.WriteLine(sLineNumber);

                                string sErrorMsg = $"{new string(' ', 7)}****** ERROR on line {LineCounter} address 0x{iAddress:X4}, Can't find mnemonic: {sLine.Trim()} ******";

                                Console.WriteLine(sLine);
                                Console.WriteLine(sErrorMsg);

                                lstFile.WriteLine(sLine);
                                lstFile.WriteLine(sErrorMsg);

                                iErrorNumber++;
                                iAddress++;
                            }
                        }

                        // If stop on error is enabled and found an error then stop

                        if ((iPass == 2) && bStopOnError && (iErrorNumber >= 1))
                        {
                            break;
                        }
                    } // end of file reading

                    if (iPass == 2)
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

                if (iPass == 1)
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

        public static int FindInstructionIndex(string sLine, int iFirstCharacterIndex, List<InstrTable> dataList)
        {
            // Defensive checks
            if (string.IsNullOrEmpty(sLine)) return -1;
            if (iFirstCharacterIndex < 0 || iFirstCharacterIndex >= sLine.Length) return -1;

            // Remove comment portion starting at ';' that is after the mnemonic start
            int commentPos = sLine.IndexOf(';', iFirstCharacterIndex);
            string codePortion;
            if (commentPos >= 0)
            {
                int len = commentPos - iFirstCharacterIndex;
                if (len <= 0) return -1;
                codePortion = sLine.Substring(iFirstCharacterIndex, len);
            }
            else
            {
                codePortion = sLine.Substring(iFirstCharacterIndex);
            }

            // Trim whitespace around the mnemonic/operands
            string subLine = codePortion.Trim();

            for (int iIndexTable = 0; iIndexTable < dataList.Count; iIndexTable++)
            {
                InstrTable instr = dataList[iIndexTable];
                //string pattern = InstrToRegex(instr.StringValue);
                //if (Regex.IsMatch(subLine, pattern, RegexOptions.IgnoreCase))
                if (instr.Regex.IsMatch(subLine))
                {
                    return iIndexTable; // Found instruction
                }
            }

            return -1; // Not found
        }

        static void WriteInstructionTable(string path, List<InstrTable> dataList)
        {
            using (var w = new StreamWriter(path))
            {
                w.WriteLine("Instruction Table");
                w.WriteLine("Mnemonic                 Opcode  Bytes  Sym Offset");
                w.WriteLine("--------------------------------------------------");

                foreach (var i in dataList)
                {
                    w.WriteLine(
                        $"{i.StringValue,-25} " +
                        $"{i.OpCode:X2}      " +
                        $"{i.NbByte,1}     " +
                        $"{i.Sym,1}   " +
                        $"{i.Offset,2}"
                    );
                }
            }
        }

        static void WriteRegexTable(string path, List<InstrTable> dataList)
        {
            using (var w = new StreamWriter(path))
            {
                foreach (var i in dataList)
                {
                    w.WriteLine($"{i.StringValue}");
                    w.WriteLine($"  Regex: {i.Regex}");
                    w.WriteLine();
                }
            }
        }

        static void WriteListingWithContinuation(
            int startAddress,
            byte[] bytes,
            string sourceLine,
            TextWriter lstFile,
            bool toConsole = false)
        {
            const int BYTES_PER_LINE = 16;  // Could be made global (for op code too...)
            const int BYTE_COLUMN_WIDTH = BYTES_PER_LINE * 3; // "XX "

            int address = startAddress;

            for (int i = 0; i < bytes.Length; i += BYTES_PER_LINE)
            {
                int count = Math.Min(BYTES_PER_LINE, bytes.Length - i);

                // Build byte field
                StringBuilder byteField = new StringBuilder();
                for (int j = 0; j < count; j++)
                    byteField.AppendFormat("{0:X2} ", bytes[i + j]);

                string paddedBytes = byteField.ToString().PadRight(BYTE_COLUMN_WIDTH);

                bool firstLine = (i == 0);
                bool lastLine = (i + count >= bytes.Length);

                string addressField = firstLine
                    ? $"{address:X4}"
                    : "    ";

                string src = lastLine ? sourceLine : "";

                string line = $"{addressField} {paddedBytes} {src}";

                lstFile.WriteLine(line);
                if (toConsole) Console.WriteLine(line);

                address += count;
            }
        }

        static bool ParseSymbolExpression(string expr, Dictionary<string, SymbolTableEntry> symbolTable, out int value)
        {
            value = 0;

            var match = Regex.Match(
                expr,
                @"^([A-Za-z_?][A-Za-z0-9_]*)(?:\s*([+-])\s*(\d+))?$"
            );

            if (!match.Success)
                return false;

            string symbol = match.Groups[1].Value;

            if (!symbolTable.ContainsKey(symbol))
                return false;

            value = symbolTable[symbol].Address;

            if (match.Groups[2].Success)
            {
                int offset = int.Parse(match.Groups[3].Value);
                if (match.Groups[2].Value == "-")
                    offset = -offset;

                value += offset;
            }

            return true;
        }

        static List<InstrTable> BuildInstructionTable()
        {
            var list = new List<InstrTable>
            {
                // OpCode : Byte value used to code each instruction
                // NbByte : Number of bytes following the OP code byte
                // Sym    : Symbolic decoding is enabled after the mnemonic 0: hex address, 1:symbolic address, 2:symbolic relative adressing (+-127)
                // Offset : Character position where the hex value start.
                // Presently only hexadecimal values are supported, 8 and 16 bits only.
                new InstrTable { StringValue = "ORG/0x****",     OpCode = 0,    NbByte = 0, Sym = OperandMode.Hex,      Offset = 6, Operation = "PC = addr",                    Flags = "-",   Desc = "Set program origin (assembly address pointer)"       },
                new InstrTable { StringValue = "DB 0x**",        OpCode = 0,    NbByte = 0, Sym = OperandMode.Hex,      Offset = 5, Operation = "MEM[PC] = byte, PC++",         Flags = "-",   Desc = "Define byte in memory at current location"           },
                new InstrTable { StringValue = "EQU 0x****",     OpCode = 0,    NbByte = 0, Sym = OperandMode.Hex,      Offset = 6, Operation = "symbol = value",               Flags = "-",   Desc = "Define constant value (no memory allocation)"        },
                new InstrTable { StringValue = ".ASCII \"@\"",   OpCode = 0,    NbByte = 0, Sym = OperandMode.Ascii,    Offset = 7, Operation = "MEM[PC..] = ASCII string",     Flags = "-",   Desc = "Store ASCII string in memory"                        },
                new InstrTable { StringValue = "INCA",           OpCode = 0x03, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "A = A + 1",                    Flags = "E",   Desc = "Increment register A"                                },
                new InstrTable { StringValue = "LDX #0x****",    OpCode = 0x04, NbByte = 2, Sym = OperandMode.Hex,      Offset = 7, Operation = "X = imm16",                    Flags = "-",   Desc = "Load 16-bit immediate value into X register"         },
                new InstrTable { StringValue = "LDX #@",         OpCode = 0x04, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 5, Operation = "X = symbol",                   Flags = "-",   Desc = "Load symbolic 16-bit value into X register"          },
                new InstrTable { StringValue = "INCX",           OpCode = 0x05, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "X = X + 1",                    Flags = "-",   Desc = "Increment register X"                                },
                new InstrTable { StringValue = "JSR 0x****",     OpCode = 0x06, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "PC -> stack, PC = addr",       Flags = "-",   Desc = "Jump to subroutine"                                  },
                new InstrTable { StringValue = "JSR @",          OpCode = 0x06, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "PC -> stack, PC = symbol",     Flags = "-",   Desc = "Jump to subroutine (symbol)"                         },
                new InstrTable { StringValue = "RTS",            OpCode = 0x07, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "PC = stack",                   Flags = "-",   Desc = "Return from subroutine"                              },
                new InstrTable { StringValue = "STOP",           OpCode = 0x08, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "halt",                         Flags = "-",   Desc = "Stop execution"                                      },
                new InstrTable { StringValue = "NOP",            OpCode = 0x09, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "none",                         Flags = "-",   Desc = "No operation"                                        },
                new InstrTable { StringValue = "LDA (X)",        OpCode = 0x0A, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "A = MEM[X]",                   Flags = "-",   Desc = "Load A from memory indexed by X"                     },
                new InstrTable { StringValue = "STA (X)",        OpCode = 0x0B, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "MEM[X] = A",                   Flags = "-",   Desc = "Store A into memory indexed by X"                    },
                new InstrTable { StringValue = "JRA 0x**",       OpCode = 0x0C, NbByte = 1, Sym = OperandMode.Hex,      Offset = 6, Operation = "PC = PC + offset",             Flags = "-",   Desc = "Unconditional relative jump"                         },
                new InstrTable { StringValue = "JRA @",          OpCode = 0x0C, NbByte = 1, Sym = OperandMode.Relative, Offset = 4, Operation = "PC = PC + offset",             Flags = "-",   Desc = "Unconditional relative jump (symbol)"                },
                new InstrTable { StringValue = "SRLA",           OpCode = 0x0D, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "0 -> A7, A >> 1, A0 -> C",     Flags = "C",   Desc = "Shift right logical A"                               },
                new InstrTable { StringValue = "SLLA",           OpCode = 0x0E, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "C <- A7, A = A << 1, A0 <- 0", Flags = "C",   Desc = "Shift left logical A"                                },
                new InstrTable { StringValue = "SLAA",           OpCode = 0x0E, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "C <- A7, A = A << 1, A0 <- 0", Flags = "C",   Desc = "Shift left arithmetic A (same as SLLA)"              },
                new InstrTable { StringValue = "JRNC @",         OpCode = 0x0F, NbByte = 1, Sym = OperandMode.Relative, Offset = 5, Operation = "if (C == 0) PC = PC + offset", Flags = "-",   Desc = "Jump relative if carry is not set"                   },
                new InstrTable { StringValue = "RRCA",           OpCode = 0x10, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "C -> A7, A >> 1, A0 -> C",     Flags = "C",   Desc = "Rotate right A through carry"                        },
                new InstrTable { StringValue = "RCF",            OpCode = 0x11, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "C <- 0",                       Flags = "C",   Desc = "Reset carry flag"                                    },
                new InstrTable { StringValue = "SCF",            OpCode = 0x12, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "C <- 1",                       Flags = "C",   Desc = "Set carry flag"                                      },
                new InstrTable { StringValue = "DECXL",          OpCode = 0x13, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "XL = XL - 1",                  Flags = "E",   Desc = "Decrement low byte of X register"                    },
                new InstrTable { StringValue = "RRC @",          OpCode = 0x14, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "C -> MEM[7:0] -> C",           Flags = "C",   Desc = "Rotate right memory byte through carry"              },
                new InstrTable { StringValue = "SRL @",          OpCode = 0x15, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "0 -> MEM[7:0] -> C",           Flags = "C",   Desc = "Shift right logical memory byte"                     },
                new InstrTable { StringValue = "STX 0x****",     OpCode = 0x16, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "MEM[addr] <- X",               Flags = "-",   Desc = "Store X register to absolute address"                },
                new InstrTable { StringValue = "STX @",          OpCode = 0x16, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "MEM[symbol] <- X",             Flags = "-",   Desc = "Store X register to symbolic address"                },
                new InstrTable { StringValue = "ORA #0x**",      OpCode = 0x17, NbByte = 1, Sym = OperandMode.Hex,      Offset = 7, Operation = "A = A OR imm",                 Flags = "-",   Desc = "Logical OR between A and immediate value"            },
                new InstrTable { StringValue = "XORA #0x**",     OpCode = 0x18, NbByte = 1, Sym = OperandMode.Hex,      Offset = 8, Operation = "A = A XOR imm",                Flags = "-",   Desc = "Exclusive OR between A and immediate value"          },
                new InstrTable { StringValue = "NOTA",           OpCode = 0x19, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "A = ~A",                       Flags = "-",   Desc = "Bitwise NOT on accumulator A"                        },
                new InstrTable { StringValue = "TEQX #0x****",   OpCode = 0x1A, NbByte = 2, Sym = OperandMode.Hex,      Offset = 8, Operation = "E <- (X == imm)",              Flags = "E",   Desc = "Compare X with immediate value"                      },
                new InstrTable { StringValue = "TEQX #@",        OpCode = 0x1A, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 6, Operation = "E <- (X == symbol)",           Flags = "E",   Desc = "Compare X with symbolic value"                       },
                new InstrTable { StringValue = "LDX s.0x**",     OpCode = 0x1B, NbByte = 1, Sym = OperandMode.Hex,      Offset = 8, Operation = "X <- MEM[addr8]",              Flags = "-",   Desc = "Load X from 8-bit absolute address"                  },
                new InstrTable { StringValue = "LDX s.@",        OpCode = 0x1B, NbByte = 1, Sym = OperandMode.Symbol,   Offset = 6, Operation = "X <- MEM[symbol8]",            Flags = "-",   Desc = "Load X from symbolic 8-bit address"                  },
                new InstrTable { StringValue = "LDA (0x****,X)", OpCode = 0x1C, NbByte = 2, Sym = OperandMode.Hex,      Offset = 7, Operation = "A <- MEM[addr + X]",           Flags = "-",   Desc = "Load A using indexed addressing (base + X)"          },
                new InstrTable { StringValue = "LDA (@,X)",      OpCode = 0x1C, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 5, Operation = "A <- MEM[symbol + X]",         Flags = "-",   Desc = "Load A using indexed symbolic addressing (base + X)" },
                new InstrTable { StringValue = "STA (0x****,X)", OpCode = 0x1D, NbByte = 2, Sym = OperandMode.Hex,      Offset = 7, Operation = "MEM[addr + X] <- A",           Flags = "-",   Desc = "Store A using indexed addressing (base + X)"         },
                new InstrTable { StringValue = "STA (@,X)",      OpCode = 0x1D, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 5, Operation = "MEM[symbol + X] <- A",         Flags = "-",   Desc = "Store A using indexed symbolic addressing (base + X)"},
                new InstrTable { StringValue = "CLRX",           OpCode = 0x1E, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "X <- 0",                       Flags = "E",   Desc = "Clear X register (sets equality flag)"               },
                new InstrTable { StringValue = "CMPA 0x****",    OpCode = 0x1F, NbByte = 2, Sym = OperandMode.Hex,      Offset = 7, Operation = "E <- (A == MEM[addr])",        Flags = "E",   Desc = "Compare A - memory (absolute address)"               },
                new InstrTable { StringValue = "CMPA @",         OpCode = 0x1F, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 5, Operation = "E <- (A == MEM[symbol])",      Flags = "E",   Desc = "Compare A - memory (symbolic address)"               },
                new InstrTable { StringValue = "DECA",           OpCode = 0x20, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "A = A - 1",                    Flags = "E",   Desc = "Decrement A register (carry unchanged)"              },
                new InstrTable { StringValue = "TEQA #0x**",     OpCode = 0x21, NbByte = 1, Sym = OperandMode.Hex,      Offset = 8, Operation = "E <- (A == imm)",              Flags = "E",   Desc = "Test A against immediate value (A & C unchanged)"    },
                new InstrTable { StringValue = "TEQA 0x****",    OpCode = 0x22, NbByte = 2, Sym = OperandMode.Hex,      Offset = 7, Operation = "E <- (A == MEM[addr])",        Flags = "E",   Desc = "Test A against memory (absolute) (A & C unchanged)"  },
                new InstrTable { StringValue = "TEQA @",         OpCode = 0x22, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 5, Operation = "E <- (A == MEM[symbol])",      Flags = "E",   Desc = "Test A against memory (symbolic) (A & C unchanged)"  },
                new InstrTable { StringValue = "JRUGE @",        OpCode = 0x23, NbByte = 1, Sym = OperandMode.Relative, Offset = 6, Operation = "if (C == 1) PC <- PC + rel",   Flags = "-",   Desc = "Jump relative if unsigned greater or equal (C=1)"    },
                new InstrTable { StringValue = "PSHA",           OpCode = 0x24, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "(SP) <- A, SP <- SP + 1",      Flags = "-",   Desc = "Push A register onto stack"                          },
                new InstrTable { StringValue = "POPA",           OpCode = 0x25, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "SP <- SP - 1, A <- (SP)",      Flags = "-",   Desc = "Pop value from stack into A"                         },
                new InstrTable { StringValue = "CLRA",           OpCode = 0x26, NbByte = 0, Sym = OperandMode.Hex,      Offset = 0, Operation = "A <- 0, E <- 1",               Flags = "E",   Desc = "Clear A register (sets E flag)"                      },
                new InstrTable { StringValue = "LDA (SP-*)",     OpCode = 0x27, NbByte = 1, Sym = OperandMode.Negative, Offset = 8, Operation = "A <- MEM[SP - offset]",        Flags = "-",   Desc = "Load A from stack with negative offset (precomputed 2's complement)"  },
                new InstrTable { StringValue = "ADCA 0x****",    OpCode = 0x28, NbByte = 2, Sym = OperandMode.Hex,      Offset = 7, Operation = "A <- A + MEM[addr] + C",       Flags = "C",   Desc = "Add memory to A with carry (absolute)"               },
                new InstrTable { StringValue = "ADCA @",         OpCode = 0x28, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 5, Operation = "A <- A + MEM[symbol] + C",     Flags = "C",   Desc = "Add memory to A with carry (symbolic)"               },
                new InstrTable { StringValue = "ADDA 0x****",    OpCode = 0x29, NbByte = 2, Sym = OperandMode.Hex,      Offset = 7, Operation = "A <- A + MEM[addr]",           Flags = "C",   Desc = "Add memory to A (absolute)"                          },
                new InstrTable { StringValue = "ADDA @",         OpCode = 0x29, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 5, Operation = "A <- A + MEM[symbol]",         Flags = "C",   Desc = "Add memory to A (symbolic)"                          },
                new InstrTable { StringValue = "LDA 0x****",     OpCode = 0x2A, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "A <- MEM[addr]",               Flags = "-",   Desc = "Load A from memory (absolute)"                       },
                new InstrTable { StringValue = "LDA @",          OpCode = 0x2A, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "A <- MEM[symbol]",             Flags = "-",   Desc = "Load A from memory (symbolic)"                       },
                new InstrTable { StringValue = "JNE 0x****",     OpCode = 0x2B, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "if (E == 0) PC <- addr",       Flags = "-",   Desc = "Jump if not equal (absolute)"                        },
                new InstrTable { StringValue = "JNE @",          OpCode = 0x2B, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "if (E == 0) PC <- symbol",     Flags = "-",   Desc = "Jump if not equal (symbolic)"                        },
                new InstrTable { StringValue = "JEQ 0x****",     OpCode = 0x2C, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "if (E == 1) PC <- addr",       Flags = "-",   Desc = "Jump if equal (absolute)"                            },
                new InstrTable { StringValue = "JEQ @",          OpCode = 0x2C, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "if (E == 1) PC <- symbol",     Flags = "-",   Desc = "Jump if equal (symbolic)"                            },
                new InstrTable { StringValue = "CMPA #0x**",     OpCode = 0x2D, NbByte = 1, Sym = OperandMode.Hex,      Offset = 8, Operation = "E,C <- (A - imm)",             Flags = "E,C", Desc = "Compare A with immediate (A - imm)"                  },
                new InstrTable { StringValue = "ADCA #0x**",     OpCode = 0x2E, NbByte = 1, Sym = OperandMode.Hex,      Offset = 8, Operation = "A <- A + imm + C",             Flags = "C",   Desc = "Add immediate to A with carry"                       },
                new InstrTable { StringValue = "ADDA #0x**",     OpCode = 0x2F, NbByte = 1, Sym = OperandMode.Hex,      Offset = 8, Operation = "A <- A + imm",                 Flags = "C",   Desc = "Add immediate to A"                                  },
                new InstrTable { StringValue = "LDA #0x**",      OpCode = 0x30, NbByte = 1, Sym = OperandMode.Hex,      Offset = 7, Operation = "A <- imm",                     Flags = "-",   Desc = "Load immediate into A"                               },
                new InstrTable { StringValue = "STA 0x****",     OpCode = 0x31, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "MEM[addr] <- A",               Flags = "-",   Desc = "Store A into memory (absolute)"                      },
                new InstrTable { StringValue = "STA @",          OpCode = 0x31, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "MEM[symbol] <- A",             Flags = "-",   Desc = "Store A into memory (symbolic)"                      },
                new InstrTable { StringValue = "JMP 0x****",     OpCode = 0x32, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "PC <- addr",                   Flags = "-",   Desc = "Unconditional jump (absolute)"                       },
                new InstrTable { StringValue = "JMP @",          OpCode = 0x32, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "PC <- symbol",                 Flags = "-",   Desc = "Unconditional jump (symbolic)"                       },
                new InstrTable { StringValue = "ANDA #0x**",     OpCode = 0x33, NbByte = 1, Sym = OperandMode.Hex,      Offset = 8, Operation = "A <- A & imm",                 Flags = "-",   Desc = "Logical AND immediate with A"                        },
                new InstrTable { StringValue = "LDX 0x****",     OpCode = 0x34, NbByte = 2, Sym = OperandMode.Hex,      Offset = 6, Operation = "X <- MEM[addr]",               Flags = "-",   Desc = "Load X from memory (absolute)"                       },
                new InstrTable { StringValue = "LDX @",          OpCode = 0x34, NbByte = 2, Sym = OperandMode.Symbol,   Offset = 4, Operation = "X <- MEM[symbol]",             Flags = "-",   Desc = "Load X from memory (symbolic)"                       },
            };

            /*
            // Keep first 3 items
            var firstThree = dataList.Take(3).ToList();

            // Sort the rest by descending StringValue length
            var restSorted = dataList.Skip(3)
                         .OrderByDescending(i => i.StringValue.Length)
                         .ToList();

            // Merge back
            dataList = firstThree.Concat(restSorted).ToList();
            */

            return list;
        }

        static void CompileRegex(List<InstrTable> dataList)
        {
            foreach (var instr in dataList)
            {
                instr.Regex = new Regex(
                    InstrToRegex(instr.StringValue),
                    RegexOptions.IgnoreCase | RegexOptions.Compiled
                );
            }
        }

        public static string InstrToRegex(string instr)
        {
            {
                var tokens = instr.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

                var tokenPatterns = tokens.Select(token =>
                {
                    string p = token;

                    // CRITICAL ORDER: from the longest to the shortest

                    // Placeholders temporaires (impossibles à confondre)
                    p = p.Replace("****", "__HEX4__");
                    p = p.Replace("**", "__HEX2__");
                    p = p.Replace("*", "__DEC__");
                    p = p.Replace("\"@\"", "__ASCII__");
                    p = p.Replace("@", "__SYMBOL__");
                    //p = p.Replace("#", "__IMM__");
                    


                    // Escape tout le reste
                    p = Regex.Escape(p);

                    // Inject real regex patterns
                    p = p.Replace("__HEX4__", @"[0-9A-Fa-f]{4}");
                    p = p.Replace("__HEX2__", @"[0-9A-Fa-f]{2}");
                    p = p.Replace("__DEC__", @"\d+");
                    p = p.Replace("__SYMBOL__", @"[A-Za-z_?][A-Za-z0-9_]*(?:\s*[+-]\s*\d+)?");
                    p = p.Replace("__ASCII__", "\"[^\"]*\"");
                    //p = p.Replace("__IMM__", @"#?");

                    return p;
                });

                string pattern = "^" + string.Join(@"\s+", tokenPatterns) + @"(?=(\s|,|$))";
                return pattern;
            }
        }

        public static bool CheckAndMarkAddress(
            int absoluteAddress,
            int iAddressEepromBegin,
            bool[] used,
            string[] owner,
            string who,
            uint lineNumber,
            ref int iErrorNumber)
        {
            int index = absoluteAddress - iAddressEepromBegin;

            if (index < 0 || index >= used.Length)
            {
                Console.WriteLine(
                    $"****** ERROR @ line {lineNumber}, address 0x{absoluteAddress:X4} outside EEPROM range ******");
                iErrorNumber++;
                return false;
            }

            if (used[index])
            {
                Console.WriteLine(
                    $"****** ERROR @ line {lineNumber}, address 0x{absoluteAddress:X4} overlaps previous code ({owner[index]}) ******");
                iErrorNumber++;
                return false;
            }

            used[index] = true;
            owner[index] = who;
            return true;
        }

        static void PrintInstructionTable(List<InstrTable> table)
        {
            Console.WriteLine("MyCPU Instruction Set");
            Console.WriteLine(new string('-', 100));

            Console.WriteLine(
               $"{Pad("Mnemonic", 22)}" +
               $"{Pad("Op", 6)}" +
               $"{Pad("Bytes", 6)}" +
               $"{Pad("Mode", 10)}" +
               $"{Pad("Flags", 8)}" +
               $"Description");

            Console.WriteLine(new string('-', 100));

            foreach (var instr in table
                .OrderBy(i => GetMnemonic(i.StringValue))
                .ThenBy(i => i.StringValue))
            {
                Console.WriteLine(
                   $"{Pad(instr.StringValue, 22)}" +
                   $"{Pad("0x" + instr.OpCode.ToString("X2"), 6)}" +
                   $"{Pad(instr.NbByte.ToString(), 6)}" +
                   $"{Pad(instr.Sym.ToString(), 10)}" +
                   $"{Pad(instr.Flags ?? "-", 8)}" +
                   $"{instr.Desc}");
            }
        }

        static string GetMnemonic(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            int idx = s.IndexOf(' ');
            return (idx == -1) ? s : s.Substring(0, idx);
        }

        static string Pad(string s, int width)
        {
            return (s ?? "").PadRight(width);
        }

    }

}




