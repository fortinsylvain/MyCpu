using System;
using System.IO;
using System.Linq;

class Program
{
    static void Main()
    {
        // Use absolute path to test.c so runtime finds the source file reliably
        string src = File.ReadAllText(@"C:\\SYLVAIN\\MyCPU\\MyCCompiler\\test.c");

        var lexer = new Lexer(src);
        var tokens = lexer.Tokenize();



        var parser = new Parser(tokens);
        var ast = parser.Parse();

        var gen = new CodeGen();
        // Enable virtual-register macro library emission for multi-byte ops
        gen.UseVRegLibrary = true;
        var asm = gen.Generate(ast);

        // If vreg library emission enabled, try to include vreg.asm content
        string outPath = @"C:\\SYLVAIN\\MyCPU\\MyCCompiler\\output.asm";
        if (gen.UseVRegLibrary)
        {
            string vregPath = @"C:\\SYLVAIN\\MyCPU\\MyCCompiler\\vreg.asm";
            if (File.Exists(vregPath))
            {
                // find all referenced library symbols in the generated asm (JSR ?name)
                var used = new HashSet<string>();
                var lines = asm.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (var line in lines)
                {
                    var t = line.Trim();
                    if (t.StartsWith("JSR "))
                    {
                        var parts = t.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                        if (parts.Length >= 2 && parts[1].StartsWith("?"))
                            used.Add(parts[1].TrimEnd());
                    }
                }

                // If nothing from the library is referenced, write asm only.
                if (used.Count == 0)
                {
                    File.WriteAllText(outPath, asm);
                }
                else
                {
                    // Read library and extract header + only referenced symbol blocks (label..RTS)
                    var libLines = File.ReadAllLines(vregPath);
                    var headerSb = new System.Text.StringBuilder();
                    int firstLabelIdx = libLines.Length;
                    for (int i = 0; i < libLines.Length; i++)
                    {
                        var t = libLines[i].TrimStart();
                        if (t.StartsWith("?mov32_") || t.StartsWith("?add32_") || t.StartsWith("?load32_") || t.StartsWith("?store32_"))
                        {
                            firstLabelIdx = i;
                            break;
                        }
                    }

                    // include header (EQUs, comments) up to first label
                    for (int i = 0; i < firstLabelIdx; i++) headerSb.AppendLine(libLines[i]);

                    var sb = new System.Text.StringBuilder();
                    for (int i = 0; i < libLines.Length; i++)
                    {
                        var l = libLines[i];
                        var t = l.TrimStart();
                        foreach (var sym in used)
                        {
                            if (t.StartsWith(sym + ":"))
                            {
                                // emit this block until RTS
                                int j = i;
                                while (j < libLines.Length)
                                {
                                    sb.AppendLine(libLines[j]);
                                    if (libLines[j].Trim().Equals("RTS", StringComparison.OrdinalIgnoreCase))
                                    {
                                        i = j; // advance outer loop
                                        break;
                                    }
                                    j++;
                                }
                                break;
                            }
                        }
                    }

                    // write header (EQUs) first, then generated asm, then the selected library blocks
                    string finalContent = headerSb.ToString() + "\n" + asm + "\n" + sb.ToString();

                    // Post-process: merge labels with their following instruction and align subsequent lines
                    var finalLines = finalContent.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None).ToList();

                    // Determine instruction column: prefer to match the `main_loop`'s
                    // instruction column so library routines line up with top-level code.
                    int instrCol = -1;
                    for (int i = 0; i < finalLines.Count; i++)
                    {
                        var s = finalLines[i];
                        if (s.TrimStart().StartsWith("main_loop:"))
                        {
                            // find position of first non-space after the colon
                            int colon = s.IndexOf(':');
                            if (colon >= 0)
                            {
                                int p = colon + 1;
                                while (p < s.Length && s[p] == ' ') p++;
                                instrCol = p;
                            }
                            break;
                        }
                    }

                    if (instrCol == -1)
                    {
                        // fallback: use max label length + 1
                        int maxLabelLen = 0;
                        for (int i = 0; i < finalLines.Count; i++)
                        {
                            string t = finalLines[i].Trim();
                            if (string.IsNullOrEmpty(t)) continue;
                            if (t.EndsWith(":"))
                            {
                                int colonIdx = t.IndexOf(':');
                                if (colonIdx >= 0)
                                {
                                    string labelPart = t.Substring(0, colonIdx + 1);
                                    if (labelPart.Length > maxLabelLen) maxLabelLen = labelPart.Length;
                                }
                            }
                        }
                        instrCol = Math.Max(1, maxLabelLen + 1);
                    }

                    // Ensure instrCol is at least one past the longest label so there's always a space
                    int globalMaxLabel = 0;
                    for (int i = 0; i < finalLines.Count; i++)
                    {
                        string t = finalLines[i].Trim();
                        if (string.IsNullOrEmpty(t)) continue;
                        if (t.EndsWith(":"))
                        {
                            int colonIdx = t.IndexOf(':');
                            if (colonIdx >= 0)
                            {
                                string labelPart = t.Substring(0, colonIdx + 1);
                                if (labelPart.Length > globalMaxLabel) globalMaxLabel = labelPart.Length;
                            }
                        }
                    }
                    instrCol = Math.Max(instrCol, globalMaxLabel + 1);

                    for (int i = 0; i < finalLines.Count; i++)
                    {
                        string trimmed = finalLines[i].Trim();
                        if (string.IsNullOrEmpty(trimmed)) continue;
                        if (trimmed.EndsWith(":"))
                        {
                            int j = i + 1;
                            while (j < finalLines.Count && string.IsNullOrWhiteSpace(finalLines[j])) j++;
                            if (j >= finalLines.Count) break;
                            string nextTrim = finalLines[j].TrimStart();
                            if (!nextTrim.StartsWith(";") && !nextTrim.EndsWith(":"))
                            {
                                int colonIdx = trimmed.IndexOf(':');
                                string labelPart = colonIdx >= 0 ? trimmed.Substring(0, colonIdx + 1) : trimmed;
                                string paddedLabel = labelPart.PadRight(instrCol);
                                finalLines[i] = paddedLabel + nextTrim;
                                finalLines.RemoveAt(j);
                                for (int k = j; k < finalLines.Count; k++)
                                {
                                    string t = finalLines[k].TrimStart();
                                    if (string.IsNullOrEmpty(t)) break;
                                    if (t.EndsWith(":")) break;
                                    if (t.StartsWith(";")) continue;
                                    finalLines[k] = new string(' ', instrCol) + t;
                                }
                            }
                        }
                    }

                    // Normalize all instruction lines: pad labels and indent instruction-only
                    // lines so every instruction starts in the same column.
                    for (int i = 0; i < finalLines.Count; i++)
                    {
                        var raw = finalLines[i];
                        if (string.IsNullOrWhiteSpace(raw)) continue;
                        string trimmed = raw.Trim();
                        // leave comments and EQU/header lines alone
                        if (trimmed.StartsWith(";") || trimmed.IndexOf("EQU", StringComparison.OrdinalIgnoreCase) >= 0)
                            continue;

                        // If the line contains a label (colon), pad the label to instrCol and
                        // place the instruction/comment after it.
                        int colonIdx = trimmed.IndexOf(':');
                        if (colonIdx >= 0)
                        {
                            string labelPart = trimmed.Substring(0, colonIdx + 1);
                            string rest = trimmed.Substring(colonIdx + 1).TrimStart();
                            if (string.IsNullOrEmpty(rest))
                            {
                                // label-only line; leave as-is
                                finalLines[i] = labelPart;
                            }
                            else
                            {
                                finalLines[i] = labelPart.PadRight(instrCol) + rest;
                            }
                        }
                        else
                        {
                            // instruction-only line: indent to instrCol
                            finalLines[i] = new string(' ', instrCol) + trimmed;
                        }
                    }

                    File.WriteAllText(outPath, string.Join("\n", finalLines));
                }
            }
            else
            {
                // fallback: just write the generated asm
                File.WriteAllText(outPath, asm);
            }
        }
        else
        {
            File.WriteAllText(outPath, asm);
        }
        Console.WriteLine("Wrote assembly to output.asm");
    }
}
