// Homebrew MyCPU microassembler program
// Author: Sylvain Fortin
// Date: 29 december 2023
// Documentation: This is a microassembler to help develop the micro-program. The source file having an extension .src 
//                is passed in argument in the command line.
//                Three output files are created:
//                - filename.lst is an ascii file of the listing with the comments.
//                - urom_lsb.bin contain the LSB binary data to be programmed on the EEPROM
//                - urom_msb.bin contain the MSB ...
//                The EEPROM programmer i am using is model TL866II Plus from XGecu.
using System;
using System.IO;
using System.Collections.Generic;

namespace UCT_Assembler
{
    class Program
    {

        static void GetRegisterNumber(string sRegisterNumber, ref int iRegisterNumber, ref int iErrorNumber)
        {
            // Convert string to integer
            if (!int.TryParse(sRegisterNumber, out iRegisterNumber) || iRegisterNumber < 0 || iRegisterNumber > 7)
            {
                Console.WriteLine();
                // Add logic for printing to a file or console (similar to PRINT statements in BASIC)
                Console.WriteLine("**** ERROR ON REGISTER NUMBER (0-7) ****");
                iErrorNumber++;
                iRegisterNumber = 0;
            }

            // Continue with the logic after the IF statement
            // ...
        }

        static void GetBitNumber(string sBitNumber, ref int iBitNumber, ref int iErrorNumber)
        {
            // Convert string to integer
            if (!int.TryParse(sBitNumber, out iBitNumber) || iBitNumber < 0 || iBitNumber > 7)
            {
                Console.WriteLine();
                // Add logic for printing to a file or console (similar to PRINT statements in BASIC)
                Console.WriteLine("**** ERREUR ON BIT NUMBER (0-7) ****");
                iErrorNumber++;
                iBitNumber = 0;
            }
        }

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


        static void Main(string[] args)
        {
            Console.WriteLine("Homebrew micro assembler start");

            string repositoryPath = "C:\\Sylvain\\MyCPU\\uCodeAssembler\\";    // Fixed path for now
            string fileName = "urom.src"; // Replace with your desired file name
            string baseFileName = Path.GetFileNameWithoutExtension(fileName);
            string fileExtension = Path.GetExtension(fileName);
            string fullPath = Path.Combine(repositoryPath, fileName);

            // Reserve space for two 2864 EEPROM
            // we have 12 bit address (A12-A0)
            const int iEpromSize = 8192;
            int[] aEepromMsb= new int[iEpromSize];
            int[] aEepromLsb = new int[iEpromSize];

            int iErrorNumber = 0;
            int iLine = 0;

            string[] TBL = new string[28];


            TBL[0] = "";        // We do not use this location
            TBL[1] = "R*>UH";
            TBL[2] = "R*>UL";
            TBL[3] = "R*>AH";
            TBL[4] = "R*>AL";
            TBL[5] = "DATA>R*";
            TBL[6] = "**H>R*";
            TBL[7] = "**H>UH";
            TBL[8] = "**H>UL";
            TBL[9] = "NAND R*-*";
            TBL[10] = "OR R*-*";
            TBL[11] = "XOR R*-*";
            TBL[12] = "AND R*-*";
            TBL[13] = "NOR R*-*";
            TBL[14] = "XNOR R*-*";
            TBL[15] = "NOT A-*";
            TBL[16] = "A>Q*";
            TBL[17] = "R*-*>A";
            TBL[18] = "R*>DATA";
            TBL[19] = "Q>R*";
            TBL[20] = "**H>AL";
            TBL[21] = "JMP_SW1";
            TBL[22] = "JMP_SW2";
            TBL[23] = "JMP_A=0";
            TBL[24] = "JMP";
            TBL[25] = "ORG/****H";
            TBL[26] = "Q*>A";
            TBL[27] = "**H>AH";
            int iTblNumberOfElement = 28;

            int iFirstCharacterIndex;
            int iPosComment;

            string sRegisterNumber;
            int iRegisterNumber = 0;
            string sNibble;
            int iNibble=0;
            string sBitNumber;
            int iBitNumber=0;

            // Code Machine
            int BS = 0;    // MSB 7:4
            int CS = 0;    // MSB 3:0
            int DS = 0;    // LSB 7:4
            int ES = 0;    // LSB 3:0

            using (StreamReader inputFile = File.OpenText(fullPath))
            using (StreamWriter lstFile = File.CreateText(Path.Combine(repositoryPath, baseFileName + ".lst")))
            //using (StreamWriter msbFile = File.CreateText(Path.Combine(repositoryPath, baseFileName + ".msb")))
            //using (StreamWriter lsbFile = File.CreateText(Path.Combine(repositoryPath, baseFileName + ".lsb")))
            {
                string sLine = "";
                while (!inputFile.EndOfStream)
                {
                    sLine = inputFile.ReadLine();
                    iFirstCharacterIndex = FindFirstNonSpaceCharacter(sLine);
                    iPosComment = sLine.IndexOf(';');   // Locate where the comment begin

                    if (iFirstCharacterIndex == -1)    // Empty line ?
                    {
                        Console.WriteLine("");
                        lstFile.WriteLine("");
                    }
                    else if (sLine.Substring(0, 1) == ";")  // Begin with ";"
                    {
                        Console.Write(new string(' ', 30));
                        lstFile.Write(new string(' ', 30));

                        Console.WriteLine(sLine);
                        lstFile.WriteLine(sLine);
                    }
                    else if (sLine.Substring(0, 1) != ";")   // Process the line only if it does not begin with comment 
                    {
                        // Find in table the ucode
                        bool bFound = false;
                        int iIndexTable = 1;    // start at first location
                        while ((iIndexTable < iTblNumberOfElement) && !bFound)
                        {
                            int iCodeLength = TBL[iIndexTable].Length;
                            int iCharPointer = 0;
                            bool bIdentical = true;

                            while ((iCharPointer < iCodeLength) && bIdentical)
                            {
                                char cCode = TBL[iIndexTable][iCharPointer];

                                if (cCode != '*')   // Compare only if not and an asterix
                                {
                                    if (iCharPointer > (sLine.Length - 1))
                                    {
                                        bIdentical = false;
                                    }
                                    else if (cCode != sLine[iCharPointer])
                                    {
                                        bIdentical = false;
                                    }
                                }
                                iCharPointer++;
                            }

                            if (bIdentical)
                            {
                                bFound = true;
                            }
                            else
                            {
                                iIndexTable++;
                            }
                        }

                        if (bFound)
                        {
                            if (iIndexTable == 25)
                            {
                                iLine = int.Parse(sLine.Substring(4, 4), System.Globalization.NumberStyles.HexNumber);
                                //Console.Write(new string(' ', 7));
                                //Console.Write(sLine.Substring(4, 6).PadRight(8));
                                Console.Write(new string(' ', 30));
                                Console.Write(sLine.Substring(0, 9));

                                // Write to output files
                                //lstFile.Write(new string(' ', 7));
                                //lstFile.Write(sLine.Substring(4, 6).PadRight(8));
                                //lstFile.Write(new string(' ', 15));
                                lstFile.Write(new string(' ', 30));
                                lstFile.Write(sLine.Substring(0, 9));

                                int iOrgPosComm = sLine.IndexOf(";");   // position of start of comments
                                if (iOrgPosComm > 0)
                                {
                                    Console.Write(new string(' ', 4)); // TAB(4)
                                    lstFile.Write(new string(' ', 4));

                                    string sOrgCommentSubstring = sLine.Substring(iOrgPosComm, Math.Min(49, sLine.Length - iOrgPosComm));
                                    Console.Write(sOrgCommentSubstring);
                                    lstFile.Write(sOrgCommentSubstring);
                                }
                                else
                                {
                                    Console.WriteLine();
                                }
                                Console.WriteLine("");
                                lstFile.WriteLine("");

                            }
                            else
                            {
                                switch (iIndexTable)
                                {
                                    case 1:
                                        BS = 0;
                                        sRegisterNumber = sLine.Substring(1, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 2:
                                        BS = 0;
                                        sRegisterNumber = sLine.Substring(1, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = 8 + iRegisterNumber;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 3:
                                        BS = 1;
                                        sRegisterNumber = sLine.Substring(1, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 4:
                                        BS = 1;
                                        sRegisterNumber = sLine.Substring(1, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = 8 + iRegisterNumber;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 5:
                                        BS = 2;
                                        sRegisterNumber = sLine.Substring(6, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 6:
                                        BS = 2;
                                        sRegisterNumber = sLine.Substring(5, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = 8 + iRegisterNumber;
                                        sNibble = sLine.Substring(0, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        DS = iNibble;
                                        sNibble = sLine.Substring(1, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        ES = iNibble;
                                        break;
                                    case 7:
                                        BS = 3;
                                        CS = 0;
                                        sNibble = sLine.Substring(0, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        DS = iNibble;
                                        sNibble = sLine.Substring(1, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        ES = iNibble;
                                        break;
                                    case 8:
                                        BS = 3;
                                        CS = 8;
                                        sNibble = sLine.Substring(0, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        DS = iNibble;
                                        sNibble = sLine.Substring(1, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        ES = iNibble;
                                        break;
                                    case 10:
                                        BS = 4;
                                        sRegisterNumber = sLine.Substring(4, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 0;
                                        sBitNumber = sLine.Substring(6, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = 8 + iBitNumber;
                                        break;
                                    case 11:
                                        BS = 4;
                                        sRegisterNumber = sLine.Substring(5, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 1;
                                        sBitNumber = sLine.Substring(7, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = iBitNumber;
                                        break;
                                    case 12:
                                        BS = 4;
                                        sRegisterNumber = sLine.Substring(5, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 2;
                                        sBitNumber = sLine.Substring(7, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = iBitNumber;
                                        break;
                                    case 14:
                                        BS = 4;
                                        sRegisterNumber = sLine.Substring(6, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 3;
                                        sBitNumber = sLine.Substring(8, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = iBitNumber;
                                        break;
                                    case 15:
                                        BS = 4;
                                        CS = 0;
                                        DS = 3;
                                        sBitNumber = sLine.Substring(6, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = 8 + iBitNumber;
                                        break;
                                    case 16:
                                        BS = 4;
                                        CS = 8;
                                        DS = 1;
                                        sBitNumber = sLine.Substring(3, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = 8 + iBitNumber;
                                        break;
                                    case 17:
                                        BS = 5;
                                        sRegisterNumber = sLine.Substring(1, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 0;
                                        sBitNumber = sLine.Substring(3, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = iBitNumber;
                                        break;
                                    case 18:
                                        BS = 5;
                                        sRegisterNumber = sLine.Substring(1, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = 8 + iRegisterNumber;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 19:
                                        BS = 6;
                                        sRegisterNumber = sLine.Substring(3, 1);
                                        GetRegisterNumber(sRegisterNumber, ref iRegisterNumber, ref iErrorNumber);
                                        CS = iRegisterNumber;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 20:
                                        BS = 6;
                                        CS = 8;
                                        sNibble = sLine.Substring(0, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        DS = iNibble;
                                        sNibble = sLine.Substring(1, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        ES = iNibble;
                                        break;
                                    case 23:
                                        BS = 0xC;
                                        CS = 8;
                                        DS = 1;
                                        ES = 0xB;
                                        break;
                                    case 24:
                                        BS = 0xC;
                                        CS = 8;
                                        DS = 0;
                                        ES = 0;
                                        break;
                                    case 26:
                                        BS = 7;
                                        CS = 0;
                                        DS = 0;
                                        sBitNumber = sLine.Substring(1, 1);
                                        GetBitNumber(sBitNumber, ref iBitNumber, ref iErrorNumber);
                                        ES = iBitNumber;
                                        break;
                                    case 27:
                                        BS = 7;
                                        CS = 8;
                                        sNibble = sLine.Substring(0, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        DS = iNibble;
                                        sNibble = sLine.Substring(1, 1);
                                        getNibble(sNibble, ref iNibble, ref iErrorNumber);
                                        ES = iNibble;
                                        break;
                                    default:
                                        // In case the OP code decoding is not implemented
                                        string sOpNotImplemented = $"{new string(' ', 7)}****** ERROR OP NOT IMPLEMENTED ******* {sLine.Substring(0, Math.Min(13, sLine.Length))}";
                                        Console.WriteLine(sOpNotImplemented);
                                        lstFile.WriteLine(sOpNotImplemented);
                                        iErrorNumber++;
                                        break;
                                }
                            }

                            if (iIndexTable != 25)  // Only if not an ORG
                            {
                                string sLA = ((iLine & 0x7800) / 2048).ToString("X");
                                string sLB = ((iLine & 0x0780) / 128).ToString("X");
                                string sLC = ((iLine & 0x0070) / 16).ToString("X");
                                string sLD = (iLine & 0x000F).ToString("X");

                                // Line number
                                string sLineNumber = sLA + sLB + sLC + sLD;
                                Console.Write(sLineNumber);
                                lstFile.Write(sLineNumber);

                                // uAssembler code
                                string sUassCode = $"{new string(' ', 7)}{BS:X}{CS:X}{DS:X}{ES:X}";
                                Console.Write(sUassCode);
                                lstFile.Write(sUassCode);

                                // Mnemonic
                                string sMnemonic = $"{new string(' ', 15)}{sLine.Substring(0, Math.Min(13, sLine.Length))}";
                                Console.Write(sMnemonic);
                                lstFile.Write(sMnemonic);

                                // Comments
                                int POSCOMM = sLine.IndexOf(';');   // Locate where the comment begin
                                if (POSCOMM > 0)
                                {
                                    string sCommentSubstring = sLine.Substring(POSCOMM, sLine.Length - POSCOMM);
                                    Console.Write(sCommentSubstring);
                                    lstFile.Write(sCommentSubstring);
                                }

                                // End of the line
                                string sEndOfLine = "\r\n";
                                Console.Write(sEndOfLine);
                                lstFile.Write(sEndOfLine);


                                aEepromMsb[iLine] = (int)(BS * 16 + CS);
                                aEepromLsb[iLine] = (int)(DS * 16 + ES);

                                iLine = iLine + 1;
                            }
                        }
                        else
                        {           // instruction not found
                            string sLA = ((iLine & 0x7800) / 2048).ToString("X");
                            string sLB = ((iLine & 0x0780) / 128).ToString("X");
                            string sLC = ((iLine & 0x0070) / 16).ToString("X");
                            string sLD = (iLine & 0x000F).ToString("X");
                            Console.Write(sLA + sLB + sLC + sLD);       // No de ligne
                            lstFile.WriteLine(sLA + sLB + sLC + sLD);
                            Console.WriteLine($"{new string(' ', 7)}****** ERROR SYNTAX CANT FIND MNEMONIC ****** {sLine.Substring(0, Math.Min(13, sLine.Length))}");
                            lstFile.WriteLine($"{new string(' ', 7)}****** ERROR SYNTAX CANT FIND MNEMONIC ****** {sLine.Substring(0, Math.Min(13, sLine.Length))}");
                            iErrorNumber++;
                            iLine = iLine + 1;
                        }
                    }

                }

                string sTemp = "Assembly complete";
                Console.WriteLine(sTemp);
                lstFile.WriteLine(sTemp);
                sTemp = "Number of errors = " + iErrorNumber;
                Console.WriteLine(sTemp);
                lstFile.WriteLine(sTemp);

                string sName_msb = Path.Combine(repositoryPath, baseFileName + "_msb.bin");
                using (BinaryWriter msbFile = new BinaryWriter(new FileStream(sName_msb, FileMode.Create)))
                {
                    foreach (byte value in aEepromMsb)
                    {
                        msbFile.Write(value);
                    }
                }
                string sName_lsb = Path.Combine(repositoryPath, baseFileName + "_lsb.bin");
                using (BinaryWriter lsbFile = new BinaryWriter(new FileStream(sName_lsb, FileMode.Create)))
                {
                    foreach (byte value in aEepromLsb)
                    {
                        lsbFile.Write(value);
                    }
                }
                Console.WriteLine("Data written to file successfully.");
            }


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


    }
}
