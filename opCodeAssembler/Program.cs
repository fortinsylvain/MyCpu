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
            Console.WriteLine("Homebrew assembler start");
            int iAddressEepromBegin = 0xE000;
            string repositoryPath = "C:\\Sylvain\\UCT\\Assembler\\";    // Fixed path for now
            string fileName = "diag.src"; // Replace with your desired file name
            string baseFileName = Path.GetFileNameWithoutExtension(fileName);
            string fileExtension = Path.GetExtension(fileName);
            string fullPath = Path.Combine(repositoryPath, fileName);

            // Reserve space for one 2864 EEPROM
            // we have 12 bit address (A12-A0)
            const int iEpromSize = 8192;
            int[] aEeprom = new int[iEpromSize];
            
            int iErrorNumber = 0;
            int iLine = 0;
            int iTotalAssembledFieldWidth = 12;

            //string[] TBL = new string[28];
            List<InstrTable> dataList = new List<InstrTable>();
            dataList.Add(new InstrTable { StringValue = "ORG/****H", OpCode = 0,    NbByte = 0, Offset = 0 });
            dataList.Add(new InstrTable { StringValue = "DB **H",    OpCode = 0,    NbByte = 0, Offset = 3 });
            dataList.Add(new InstrTable { StringValue = "LDA #**H",  OpCode = 0x30, NbByte = 1, Offset = 5 });  // LDA #**H     LOAD IMMEDIATE VALUE IN REGISTER A
            dataList.Add(new InstrTable { StringValue = "STA ****H", OpCode = 0x31, NbByte = 2, Offset = 4 });  // STA ****H    STORE REG.A TO ADDRESSE
            dataList.Add(new InstrTable { StringValue = "JMP ****H", OpCode = 0x32, NbByte = 2, Offset = 4 });  // JMP ****H    JUMP INCONDITIONAL TO ADDRESS
            dataList.Add(new InstrTable { StringValue = "ANDA #**H", OpCode = 0x33, NbByte = 1, Offset = 6 });  // ANDA #**H    REGISTER A AND LOGICAL WITH IMMEDIATE 
            dataList.Add(new InstrTable { StringValue = "NOTA",      OpCode = 0x36, NbByte = 0, Offset = 0 });  // NOT LOGIC ON REG A
                                                                                                                // OP.2B JNEQ ****JUMP IF E = 0
                                                                                                                // OP.2C JEQ ****JUMP IF E = 1
                                                                                                                // OP.2D CMPA** COMPARE A WITH IMMEDIATE VALUE
                                                                                                                // OP.2E ADCA** ACCA+M + C > ACCA     C UPDATED
                                                                                                                // OP.2F ADDA** ACCA+M > ACCA     C UPDATED
                                                                                                                
                                                                                                                // OP.34 ORA #**H   LOGICAL OR BETWEEN REG A AND BYTE
                                                                                                                // OP.35 EXORA #**H   EXCLUSIVE OR BETWWEN A AND VALUE
                                                                                                                // OP.37 INCA INCREMENT REGISTRE A

            string sRegisterNumber;
            int iRegisterNumber = 0;
            string sNibble;
            int iNibble = 0;
            string sBitNumber;
            int iBitNumber = 0;
            int iPosComment;

            // Code Machine
            int BS = 0;    // MSB 7:4
            int CS = 0;    // MSB 3:0
            int DS = 0;    // LSB 7:4
            int ES = 0;    // LSB 3:0
            int iMsq = 0;
            int iLsq = 0;
            int[] iOpData = new int[5]; // Creates an array of 5 integers
            
            using (StreamReader inputFile = File.OpenText(fullPath))
            using (StreamWriter lstFile = File.CreateText(Path.Combine(repositoryPath, baseFileName + ".lst")))
            //using (StreamWriter msbFile = File.CreateText(Path.Combine(repositoryPath, baseFileName + ".msb")))
            //using (StreamWriter lsbFile = File.CreateText(Path.Combine(repositoryPath, baseFileName + ".lsb")))
            {
                string sLine = "";
                while (!inputFile.EndOfStream)
                {
                    sLine = inputFile.ReadLine();
                    iPosComment = sLine.IndexOf(';');   // Locate where the comment begin

                    if (sLine.Substring(0, 1) != ";")   // Process the line only if it does not begin with comment 
                    {
                        // Find in table the ucode
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
                                //char cCode = TBL[iIndexTable][iCharPointer];
                                char cCode = data.StringValue[iCharPointer];

                                if (cCode != '*')   // Compare only if not and an asterix
                                {
                                    if (cCode != sLine[iCharPointer])
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

                                if (iPosComment > 0)
                                {
                                    Console.Write(new string(' ', 4)); // TAB(4)
                                    lstFile.Write(new string(' ', 4));

                                    string sOrgCommentSubstring = sLine.Substring(iPosComment, Math.Min(49, sLine.Length - iPosComment));
                                    Console.Write(sOrgCommentSubstring);
                                    lstFile.Write(sOrgCommentSubstring);
                                }
                                else
                                {
                                    //Console.WriteLine();
                                }
                                Console.WriteLine("");
                                lstFile.WriteLine("");

                            }
                            if (iIndexTable == 1)   // DB
                            {
                                iOffset = dataList[iIndexTable].Offset;
                                sNibble = sLine.Substring(iOffset, 1);
                                getNibble(sNibble, ref iMsq, ref iErrorNumber);
                                sNibble = sLine.Substring(iOffset + 1, 1);
                                getNibble(sNibble, ref iLsq, ref iErrorNumber);
                                iOpData[0] = 16 * iMsq + iLsq;
                            }
                            else    // Mnemonic to assemble
                            {
                                switch (dataList[iIndexTable].NbByte)   // How may byte follow
                                {

                                    case 0:     // No byte following, we only have the opcode
                                        iOpData[0] = dataList[iIndexTable].OpCode;
                                        break;
                                    case 1:     // One byte after opcode
                                        iOpData[0] = dataList[iIndexTable].OpCode;
                                        iOffset = dataList[iIndexTable].Offset;
                                        sNibble = sLine.Substring(iOffset, 1);
                                        getNibble(sNibble, ref iMsq, ref iErrorNumber);
                                        sNibble = sLine.Substring(iOffset + 1, 1);
                                        getNibble(sNibble, ref iLsq, ref iErrorNumber);
                                        iOpData[1] = 16 * iMsq + iLsq;
                                        break;
                                    case 2:     // Two bytes after opcode
                                        iOpData[0] = dataList[iIndexTable].OpCode;
                                        iOffset = dataList[iIndexTable].Offset;
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
                                // Line number
                                string sLineNumber = iLine.ToString("X");
                                Console.Write(sLineNumber);
                                lstFile.Write(sLineNumber);

                                // Assembled result
                                string sAssembledCode = "";
                                for(int i = 0; i < dataList[iIndexTable].NbByte+1; i++)
                                {
                                    sAssembledCode = sAssembledCode + " " + iOpData[i].ToString("X2");
                                }
                                string sAllignedAssembledCode = "";
                                sAllignedAssembledCode = sAssembledCode.PadRight(iTotalAssembledFieldWidth);
                                Console.Write(sAllignedAssembledCode);
                                lstFile.Write(sAllignedAssembledCode);

                                // Mnemonic
                                string sMnemonic = "";
                                if (iPosComment == -1)   // No comment found
                                {
                                    sMnemonic = sLine.Substring(0, sLine.Length);
                                }
                                else
                                {
                                    sMnemonic = sLine.Substring(0, 12);
                                }
                                
                                Console.Write(sMnemonic);
                                lstFile.Write(sMnemonic);

                                // Comments
                                if (iPosComment > 0)
                                {
                                    string sCommentSubstring = sLine.Substring(iPosComment, sLine.Length - iPosComment);
                                    Console.Write(sCommentSubstring);
                                    lstFile.Write(sCommentSubstring);
                                }

                                // End of the line
                                string sEndOfLine = "\r\n";
                                Console.Write(sEndOfLine);
                                lstFile.Write(sEndOfLine);

                                // Store in EEPROM number of bytes and update line number accordingly
                                for (int i = 0; i < dataList[iIndexTable].NbByte + 1; i++)
                                {
                                    aEeprom[iLine - iAddressEepromBegin] = iOpData[i];
                                    iLine = iLine + 1;
                                }

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

                string sName_msb = Path.Combine(repositoryPath, baseFileName + ".bin");
                using (BinaryWriter msbFile = new BinaryWriter(new FileStream(sName_msb, FileMode.Create)))
                {
                    foreach (byte value in aEeprom)
                    {
                        msbFile.Write(value);
                    }
                }
                
                Console.WriteLine("Data written to file successfully.");
            }

            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();


        }


    }
}
