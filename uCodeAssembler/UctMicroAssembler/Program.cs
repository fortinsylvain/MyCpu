using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;

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
                Console.WriteLine("**** ERROR ON REGISTER NUMBER (0-7) ****");
                iErrorNumber++;
                iRegisterNumber = 0;
            }
        }

        static void GetBitNumber(string sBitNumber, ref int iBitNumber, ref int iErrorNumber)
        {
            // Convert string to integer
            if (!int.TryParse(sBitNumber, out iBitNumber) || iBitNumber < 0 || iBitNumber > 7)
            {
                Console.WriteLine();
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
            int[] aEepromMsb = new int[iEpromSize];
            int[] aEepromLsb = new int[iEpromSize];

            int iErrorNumber = 0;
            int iLine = 0;

            string[] TBL = new string[30];

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
            TBL[28] = "JMP_A=1";

            int iTblNumberOfElement = 29;

            int iFirstCharacterIndex;
            int iPosComment;

            string sRegisterNumber;
            int iRegisterNumber = 0;
            string sNibble;
            int iNibble = 0;
            string sBitNumber;
            int iBitNumber = 0;

            // Code Machine
            int BS = 0;    // MSB 7:4    S C3 C2 C1
            int CS = 0;    // MSB 3:0   C0 R2 R1 R0
            int DS = 0;    // LSB 7:4   -  -  P2 P1
            int ES = 0;    // LSB 3:0   P0 S2 S1 S0

            // Read all lines and run a two-pass label preprocessor
            List<string> srcLines = new List<string>();
            if (!File.Exists(fullPath))
            {
                Console.WriteLine("Source file not found: " + fullPath);
                return;
            }
            srcLines = File.ReadAllLines(fullPath).ToList();
            List<string> originalLines = new List<string>(srcLines);

            // Pass 1: collect labels and their addresses
            var labelTable = BuildLabelTable(srcLines, TBL, iTblNumberOfElement);
            var equTable = BuildEquTable(srcLines);

            // Resolve label operands of the form LABEL.MSB and LABEL.LSB
            List<string> processedLines = ResolveLabelOperands(srcLines, labelTable);

            using (StreamWriter lstFile = File.CreateText(Path.Combine(repositoryPath, baseFileName + ".lst")))
            {
                string sLine = "";
                int readIndex = 0;
                while (readIndex < processedLines.Count)
                {
                    string originalLine = originalLines[readIndex];
                    sLine = processedLines[readIndex];
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

                        Console.WriteLine(originalLine);
                        lstFile.WriteLine(originalLine);
                    }
                    else if (sLine.Substring(0, 1) != ";")   // Process the line only if it does not begin with comment 
                    {
                        // split code and comment (preserve comment in lst)
                        string codePart = (iPosComment >= 0 ? sLine.Substring(0, iPosComment) : sLine).TrimEnd();
                        string commentPart = (iPosComment >= 0 ? sLine.Substring(iPosComment) : "");
                        string originalCodePart = (originalLine.IndexOf(';') >= 0 ? originalLine.Substring(0, originalLine.IndexOf(';')) : originalLine).TrimEnd();

                        // Ignore constant declarations such as "RAM_START EQU 0000H"
                        if (TryParseEquDefinition(codePart, out _, out _))
                        {
                            Console.WriteLine(originalLine.TrimEnd());
                            lstFile.WriteLine(originalLine.TrimEnd());
                            readIndex++;
                            continue;
                        }

                        // detect leading label (LABEL:) in codePart and validate name
                        string instructionPart = codePart;
                        int colonPosInCode = codePart.IndexOf(':');
                        if (colonPosInCode > 0)
                        {
                            string possibleLabel = codePart.Substring(0, colonPosInCode).Trim();
                            bool isValidLabel = false;
                            if (!string.IsNullOrEmpty(possibleLabel))
                            {
                                char first = possibleLabel[0];
                                if (char.IsLetter(first) || first == '_')
                                {
                                    isValidLabel = true;
                                    for (int c = 1; c < possibleLabel.Length; c++)
                                    {
                                        char ch = possibleLabel[c];
                                        if (!(char.IsLetterOrDigit(ch) || ch == '_'))
                                        {
                                            isValidLabel = false;
                                            break;
                                        }
                                    }
                                }
                            }

                            if (isValidLabel)
                            {
                                // strip label from code to leave only the instruction (may become empty)
                                instructionPart = codePart.Substring(colonPosInCode + 1).TrimStart();
                            }
                        }

                        // If the line contains only a label (no instruction), print it and continue
                        if (string.IsNullOrEmpty(instructionPart))
                        {
                            // Preserve same formatting for listing output using the original source line
                            Console.Write(new string(' ', 30));
                            Console.WriteLine(originalLine.TrimEnd());
                            lstFile.WriteLine(originalLine.TrimEnd());
                            // do not increment iLine (label only)
                            readIndex++;
                            continue;
                        }

                        string sUcodeUser = instructionPart;
                        int iUcodeUserLength = sUcodeUser.Length;     // Get its length

                        // Find in table the ucode
                        bool bFound = false;
                        int iIndexTable = 1;    // start at first location

                        while ((iIndexTable < iTblNumberOfElement) && !bFound)
                        {
                            string sUcodeTable = TBL[iIndexTable];
                            int iUcodeLengthTable = TBL[iIndexTable].Length;
                            int iCharPointer = 0;
                            bool bIdentical = true;

                            if (iUcodeUserLength == iUcodeLengthTable)
                            {
                                while ((iCharPointer < iUcodeLengthTable) && bIdentical)    // If size same them scan each char
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
                            else
                            {
                                iIndexTable++;  // Else check next entry in table
                            }
                        }

                        if (bFound)
                        {
                            if (iIndexTable == 25)
                            {
                                try
                                {
                                    iLine = int.Parse(sLine.Substring(4, 4), System.Globalization.NumberStyles.HexNumber);
                                }
                                catch
                                {
                                    // keep previous behavior on parse failure
                                    iLine = iLine;
                                }

                                // Use the same fixed-width layout for ORG pseudo-ops as regular instructions
                                string commentPartOrg = (iPosComment >= 0 ? sLine.Substring(iPosComment) : "");
                                string sLA = ((iLine & 0x7800) / 2048).ToString("X");
                                string sLB = ((iLine & 0x0780) / 128).ToString("X");
                                string sLC = ((iLine & 0x0070) / 16).ToString("X");
                                string sLD = (iLine & 0x000F).ToString("X");

                                string sLineNumber = sLA + sLB + sLC + sLD;
                                const int assembledFieldWidth = 11;
                                const int commentColumn = 35;
                                const int separatorWidth = 2;

                                string sUassCode = new string(' ', assembledFieldWidth);
                                string mnemonicSource = !string.IsNullOrWhiteSpace(originalCodePart) ? originalCodePart.Trim() : originalLine.TrimEnd();
                                int mnemonicWidth = Math.Max(1, commentColumn - (sLineNumber.Length + sUassCode.Length + separatorWidth));
                                string mnemonicDisplay = mnemonicSource.Length <= mnemonicWidth ? mnemonicSource : mnemonicSource.Substring(0, mnemonicWidth);
                                string mnemonicPadded = ("  " + mnemonicDisplay).PadRight(separatorWidth + mnemonicWidth);

                                // Keep ORG in the same source column as the original instruction text.
                                string finalOrgLine = sLineNumber + sUassCode + new string(' ', 2 + 16) + "  " + mnemonicDisplay.PadRight(20);
                                if (!string.IsNullOrEmpty(commentPartOrg))
                                    finalOrgLine += commentPartOrg;

                                Console.WriteLine(finalOrgLine);
                                lstFile.WriteLine(finalOrgLine);
                            }
                            else
                            {
                                switch (iIndexTable)
                                {
                                    case 1:     // R*>UH
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
                                    case 23:        // JMP_A=0
                                        BS = 0xC;
                                        CS = 8;
                                        DS = 1;     // A
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
                                    case 28:        // JMP_A=1
                                        BS = 0xC;
                                        CS = 8;
                                        DS = 3;     // NOT A
                                        ES = 0xB;
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
                                // --- strict, single-line printing with fixed columns (replace existing printing block) ---
                                int assembledFieldWidth = 11; // fixed width for assembled-code area
                                int commentColumn = 35;       // absolute column where comments must start

                                // Build line-number (4 hex chars)
                                string sLA = ((iLine & 0x7800) / 2048).ToString("X");
                                string sLB = ((iLine & 0x0780) / 128).ToString("X");
                                string sLC = ((iLine & 0x0070) / 16).ToString("X");
                                string sLD = (iLine & 0x000F).ToString("X");
                                string sLineNumber = sLA + sLB + sLC + sLD; // 4 chars

                                // Build assembled field (always exactly assembledFieldWidth chars)
                                string sUassCode;
                                if (iIndexTable == 25) // ORG
                                {
                                    sUassCode = new string(' ', assembledFieldWidth);
                                }
                                else
                                {
                                    string codeHex = $"{BS:X}{CS:X}{DS:X}{ES:X}";
                                    sUassCode = codeHex.PadLeft(assembledFieldWidth); // right aligned in fixed field
                                }

                                // Choose mnemonic source
                                string mnemonicSource;
                                if (iIndexTable == 25)
                                {
                                    mnemonicSource = string.IsNullOrWhiteSpace(codePart) ? sLine.TrimEnd() : codePart.Trim();
                                }
                                else
                                {
                                    mnemonicSource = string.IsNullOrWhiteSpace(sUcodeUser) ? (string.IsNullOrWhiteSpace(codePart) ? sLine.TrimEnd() : codePart.Trim()) : sUcodeUser.Trim();
                                }

                                // Compute prefix length and mnemonic width so commentColumn is respected
                                int prefixLen = sLineNumber.Length + sUassCode.Length + 2; // +2 for the two-space separator
                                int maxMnemonicWidth = Math.Max(1, commentColumn - prefixLen);

                                // Prepare mnemonic display and pad to maxMnemonicWidth
                                string mnemonicDisplay = mnemonicSource.Length <= maxMnemonicWidth ? mnemonicSource : mnemonicSource.Substring(0, maxMnemonicWidth);
                                string mnemonicPadded = ("  " + mnemonicDisplay).PadRight(2 + maxMnemonicWidth); // keep two-space separator

                                // Build and write final line using both the resolved mnemonic and the original source text.
                                string procCommentToPrint = "";
                                int procCommentPos = sLine.IndexOf(';');
                                if (procCommentPos >= 0)
                                    procCommentToPrint = sLine.Substring(procCommentPos);

                                string originalText = originalLine.TrimEnd();
                                int origCommentPos = originalText.IndexOf(';');
                                if (origCommentPos >= 0)
                                    originalText = originalText.Substring(0, origCommentPos).TrimEnd();

                                string originalColumn = originalText;
                                if (string.IsNullOrWhiteSpace(originalColumn))
                                    originalColumn = "";

                                string resolvedMnemonic = mnemonicSource.Trim();
                                string resolvedColumn = resolvedMnemonic;
                                string finalLine = sLineNumber + sUassCode + "  " + resolvedColumn.PadRight(16) + "  " + originalColumn.PadRight(20) + procCommentToPrint;
                                Console.WriteLine(finalLine);
                                lstFile.WriteLine(finalLine);


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

                    readIndex++;
                }

                string sTemp = "Assembly complete";
                Console.WriteLine(sTemp);
                lstFile.WriteLine(sTemp);
                sTemp = "Number of errors = " + iErrorNumber;
                Console.WriteLine(sTemp);
                lstFile.WriteLine(sTemp);

                // Print label table at the end of the listing and console
                // Compact, column-aligned label table (Name | UH | UL | Addr | Value)
                if (labelTable != null && labelTable.Count > 0)
                {
                    var entries = labelTable
                        .Where(e => !equTable.ContainsKey(e.Key))
                        .OrderBy(e => e.Value)
                        .ToList();

                    if (entries.Count > 0)
                    {
                        int nameWidth = 20;

                        string header = string.Format("{0,-" + nameWidth + "}  {1,6}  {2,6}  {3,8}",
                                                      "Name", "UH", "UL", "Addr");

                        Console.WriteLine();
                        Console.WriteLine("Label table:");
                        Console.WriteLine(header);
                        string sep = new string('-', header.Length);
                        Console.WriteLine(sep);

                        lstFile.WriteLine();
                        lstFile.WriteLine("Label table:");
                        lstFile.WriteLine(header);
                        lstFile.WriteLine(sep);

                        foreach (var entry in entries)
                        {
                            int addr = entry.Value;
                            int uh = (addr >> 7) & 0xFF;   // bits 14:7
                            int ul = addr & 0x7F;          // bits 6:0
                            string uhStr = "0x" + uh.ToString("X2") + "H";
                            string ulStr = "0x" + ul.ToString("X2") + "H";
                            string addrHex = "0x" + addr.ToString("X4");

                            string line = string.Format("{0,-" + nameWidth + "}  {1,6}  {2,6}  {3,8}",
                                                        entry.Key, uhStr, ulStr, addrHex);

                            Console.WriteLine(line);
                            lstFile.WriteLine(line);
                        }
                    }
                }

                if (equTable != null && equTable.Count > 0)
                {
                    var constantEntries = equTable.OrderBy(e => e.Value).ToList();
                    int nameWidth = 20;

                    string header = string.Format("{0,-" + nameWidth + "}  {1,8}",
                                                  "Name", "Addr");

                    Console.WriteLine();
                    Console.WriteLine("Memory map constants:");
                    Console.WriteLine(header);
                    string sep = new string('-', header.Length);
                    Console.WriteLine(sep);

                    lstFile.WriteLine();
                    lstFile.WriteLine("Memory map constants:");
                    lstFile.WriteLine(header);
                    lstFile.WriteLine(sep);

                    foreach (var entry in constantEntries)
                    {
                        string addrHex = "0x" + entry.Value.ToString("X4");
                        string line = string.Format("{0,-" + nameWidth + "}  {1,8}",
                                                    entry.Key, addrHex);

                        Console.WriteLine(line);
                        lstFile.WriteLine(line);
                    }
                }

                string sName_msb = Path.Combine(repositoryPath, baseFileName + "_msb.bin");
                using (BinaryWriter msbFile = new BinaryWriter(new FileStream(sName_msb, FileMode.Create)))
                {
                    foreach (int value in aEepromMsb)
                    {
                        msbFile.Write((byte)(value & 0xFF));
                    }
                }
                string sName_lsb = Path.Combine(repositoryPath, baseFileName + "_lsb.bin");
                using (BinaryWriter lsbFile = new BinaryWriter(new FileStream(sName_lsb, FileMode.Create)))
                {
                    foreach (int value in aEepromLsb)
                    {
                        lsbFile.Write((byte)(value & 0xFF));
                    }
                }
                Console.WriteLine("Data written to file successfully.");
            }
        }

        static int FindFirstNonSpaceCharacter(string input)
        {
            if (string.IsNullOrEmpty(input))
                return -1;

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

        static bool IsValidIdentifier(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return false;

            char first = text[0];
            if (!(char.IsLetter(first) || first == '_'))
                return false;

            for (int c = 1; c < text.Length; c++)
            {
                char ch = text[c];
                if (!(char.IsLetterOrDigit(ch) || ch == '_'))
                    return false;
            }

            return true;
        }

        static bool TryParseNumericValue(string text, out int value)
        {
            value = 0;
            if (string.IsNullOrWhiteSpace(text))
                return false;

            string s = text.Trim();

            if (s.EndsWith("H", StringComparison.OrdinalIgnoreCase))
                s = s.Substring(0, s.Length - 1);

            if (s.StartsWith("0X", StringComparison.OrdinalIgnoreCase))
                s = s.Substring(2);

            if (s.StartsWith("$", StringComparison.OrdinalIgnoreCase))
                s = s.Substring(1);

            if (string.IsNullOrWhiteSpace(s))
                return false;

            if (int.TryParse(s, System.Globalization.NumberStyles.HexNumber, System.Globalization.CultureInfo.InvariantCulture, out value))
                return true;

            if (int.TryParse(s, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out value))
                return true;

            return false;
        }

        static bool TryParseEquDefinition(string codeOnly, out string symbolName, out int symbolValue)
        {
            symbolName = null;
            symbolValue = 0;

            if (string.IsNullOrWhiteSpace(codeOnly))
                return false;

            string trimmed = codeOnly.Trim();
            int equIndex = trimmed.IndexOf("EQU", StringComparison.OrdinalIgnoreCase);
            if (equIndex <= 0)
                return false;

            string left = trimmed.Substring(0, equIndex).Trim();
            string right = equIndex >= 0 && equIndex < trimmed.Length - 1
                ? trimmed.Substring(equIndex + (trimmed.Substring(equIndex, 1).Equals("=", StringComparison.Ordinal) ? 1 : 3)).Trim()
                : "";

            if (!IsValidIdentifier(left))
                return false;

            if (!TryParseNumericValue(right, out symbolValue))
                return false;

            symbolName = left;
            return true;
        }

        static Dictionary<string, int> BuildEquTable(List<string> lines)
        {
            var constants = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

            foreach (var raw in lines)
            {
                if (string.IsNullOrWhiteSpace(raw))
                    continue;

                string trimmed = raw.Trim();
                if (trimmed.StartsWith(";", StringComparison.Ordinal))
                    continue;

                int commentIndex = trimmed.IndexOf(';');
                string codeOnly = commentIndex >= 0 ? trimmed.Substring(0, commentIndex).TrimEnd() : trimmed;

                if (TryParseEquDefinition(codeOnly, out string name, out int value))
                    constants[name] = value;
            }

            return constants;
        }

        // Build label table: label (no trailing ':') -> address (simulated iLine)
        static Dictionary<string, int> BuildLabelTable(List<string> lines, string[] TBL, int iTblNumberOfElement)
        {
            var labels = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            int iLineSim = 0;

            for (int idx = 0; idx < lines.Count; idx++)
            {
                string raw = lines[idx];
                if (string.IsNullOrWhiteSpace(raw))
                    continue;

                string trimmed = raw.Trim();

                // Skip full-line comments
                if (trimmed.StartsWith(";"))
                    continue;

                // Remove comment part for label/instruction detection
                int commentIndex = trimmed.IndexOf(';');
                string codeOnly = commentIndex >= 0 ? trimmed.Substring(0, commentIndex).TrimEnd() : trimmed;

                // Handle constant definitions such as "STACK_START EQU 00A0H" or "STACK_START = 00A0H"
                if (TryParseEquDefinition(codeOnly, out string equName, out int equValue))
                {
                    labels[equName] = equValue;
                    continue;
                }

                // detect label at start in the code-only part: "LABEL:" or "LABEL: instruction..."
                int colonPos = codeOnly.IndexOf(':');
                string afterLabel = codeOnly;
                if (colonPos > 0)
                {
                    string labelName = codeOnly.Substring(0, colonPos).Trim();

                    // Accept only valid identifier-style label names: start with letter or '_' and contain only letters/digits/'_'
                    bool isValidLabel = false;
                    if (!string.IsNullOrEmpty(labelName))
                    {
                        char first = labelName[0];
                        if (char.IsLetter(first) || first == '_')
                        {
                            isValidLabel = true;
                            for (int c = 1; c < labelName.Length; c++)
                            {
                                char ch = labelName[c];
                                if (!(char.IsLetterOrDigit(ch) || ch == '_'))
                                {
                                    isValidLabel = false;
                                    break;
                                }
                            }
                        }
                    }

                    if (isValidLabel && !labels.ContainsKey(labelName))
                    {
                        labels[labelName] = iLineSim;
                    }

                    afterLabel = codeOnly.Substring(colonPos + 1).TrimStart();
                }

                // If nothing after label (label alone on a line), do not advance address
                if (string.IsNullOrEmpty(afterLabel))
                    continue;

                // Now decide if afterLabel is ORG or an instruction that consumes one address
                // Use the code-only afterLabel (comments already removed)
                int iIndexTable = 1;
                bool bFound = false;
                int iUcodeUserLength = afterLabel.Length;

                while ((iIndexTable < iTblNumberOfElement) && !bFound)
                {
                    int iUcodeLengthTable = TBL[iIndexTable].Length;
                    int iCharPointer = 0;
                    bool bIdentical = true;

                    if (iUcodeUserLength == iUcodeLengthTable)
                    {
                        while ((iCharPointer < iUcodeLengthTable) && bIdentical)
                        {
                            char cCode = TBL[iIndexTable][iCharPointer];
                            if (cCode != '*')
                            {
                                if (iCharPointer > (afterLabel.Length - 1))
                                {
                                    bIdentical = false;
                                }
                                else if (cCode != afterLabel[iCharPointer])
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
                    else
                    {
                        iIndexTable++;
                    }
                }

                if (bFound && iIndexTable == 25) // ORG sets address explicitly
                {
                    // Expect format like "ORG/XXXXH" where XXXX is 4 hex digits starting at position 4
                    if (afterLabel.Length >= 8 && afterLabel.StartsWith("ORG/"))
                    {
                        try
                        {
                            int newAddr = int.Parse(afterLabel.Substring(4, 4), System.Globalization.NumberStyles.HexNumber);
                            iLineSim = newAddr;
                        }
                        catch
                        {
                            // ignore parse error in pass1; main pass will report
                        }
                    }
                }
                else if (bFound)
                {
                    // any other instruction consumes one address
                    iLineSim++;
                }
                else
                {
                    // not found - assume it consumes one address to be conservative
                    iLineSim++;
                }
            }

            return labels;
        }



        // Resolve occurrences like "LABEL.UH" and "LABEL.UL" before comments
        static List<string> ResolveLabelOperands(List<string> lines, Dictionary<string, int> labels)
        {
            var outLines = new List<string>(lines.Count);

            var uhRegex = new System.Text.RegularExpressions.Regex(@"\b(?<label>[A-Za-z0-9_]+)\.UH\b", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            var ulRegex = new System.Text.RegularExpressions.Regex(@"\b(?<label>[A-Za-z0-9_]+)\.UL\b", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            var msbRegex = new System.Text.RegularExpressions.Regex(@"\b(?<label>[A-Za-z0-9_]+)\.MSB\b", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            var lsbRegex = new System.Text.RegularExpressions.Regex(@"\b(?<label>[A-Za-z0-9_]+)\.LSB\b", System.Text.RegularExpressions.RegexOptions.IgnoreCase);

            foreach (var raw in lines)
            {
                if (string.IsNullOrWhiteSpace(raw))
                {
                    outLines.Add(raw);
                    continue;
                }

                // split code and comment parts (keep comment verbatim)
                int commentPos = raw.IndexOf(';');
                string codePart = commentPos >= 0 ? raw.Substring(0, commentPos) : raw;
                string commentPart = commentPos >= 0 ? raw.Substring(commentPos) : "";

                // replace UH tokens (bits 14:7 -> 8 bits)
                codePart = uhRegex.Replace(codePart, m =>
                {
                    string name = m.Groups["label"].Value;
                    if (labels.TryGetValue(name, out int addr))
                    {
                        // UH = bits <14:7>
                        int uh = (addr >> 7) & 0xFF;
                        return uh.ToString("X2") + "H";
                    }
                    return m.Value; // leave unchanged if not found
                });

                // replace UL tokens (bits 6:0 -> 7 bits)
                codePart = ulRegex.Replace(codePart, m =>
                {
                    string name = m.Groups["label"].Value;
                    if (labels.TryGetValue(name, out int addr))
                    {
                        // UL = bits <6:0>
                        int ul = addr & 0x7F;
                        return ul.ToString("X2") + "H";
                    }
                    return m.Value;
                });

                // replace MSB tokens (high byte of 16-bit address)
                codePart = msbRegex.Replace(codePart, m =>
                {
                    string name = m.Groups["label"].Value;
                    if (labels.TryGetValue(name, out int addr))
                    {
                        int msb = (addr >> 8) & 0xFF;
                        return msb.ToString("X2") + "H";
                    }
                    return m.Value;
                });

                // replace LSB tokens (low byte of 16-bit address)
                codePart = lsbRegex.Replace(codePart, m =>
                {
                    string name = m.Groups["label"].Value;
                    if (labels.TryGetValue(name, out int addr))
                    {
                        int lsb = addr & 0xFF;
                        return lsb.ToString("X2") + "H";
                    }
                    return m.Value;
                });

                outLines.Add(codePart + commentPart);
            }

            return outLines;
        }

    }
}
