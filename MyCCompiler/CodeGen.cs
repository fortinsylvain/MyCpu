using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

public class CodeGen
{
    private SymbolTable symbols = new();
    private StringBuilder sb = new();
    private Dictionary<string, FunctionNode> functions = new();
    private Dictionary<string, int> elideImmediates = new();
    // When true the code generator will emit calls to the virtual-register
    // macro library (JSR ?add16_*, JSR ?add32_*, etc.) for multi-byte ops.
    public bool UseVRegLibrary { get; set; } = false;

    public string Generate(List<AstNode> nodes)
    {
        elideImmediates.Clear();

        // Analyze top-level assigns that can be elided: assigned a constant
        // and only used as call arguments (and not reassigned).
        for (int i = 0; i < nodes.Count; i++)
        {
            if (nodes[i] is AssignNode a && a.Expr is NumberNode num)
            {
                string name = a.Name;
                bool reassigned = false;
                int uses = 0;
                int callUses = 0;
                for (int j = i + 1; j < nodes.Count; j++)
                {
                    if (nodes[j] is AssignNode aa && aa.Name == name)
                    {
                        reassigned = true;
                        break;
                    }
                    uses += CountVarUses(nodes[j], name);
                    // count call-arg uses
                    if (nodes[j] is CallNode c3)
                    {
                        foreach (var arg in c3.Args)
                            if (ArgIsVarName(arg, name)) callUses++;
                    }
                    else if (nodes[j] is AssignNode a2 && a2.Expr is CallNode c2)
                    {
                        foreach (var arg in c2.Args)
                            if (ArgIsVarName(arg, name)) callUses++;
                    }
                }
                if (!reassigned && uses > 0 && uses == callUses)
                    elideImmediates[name] = num.Value;
            }
        }

        // First pass: register symbols (variables + temps + retval)
        foreach (var n in nodes)
            RegisterSymbols(n);

        // Collect functions and reserve a temporary slot (caller must allocate frame slots before calling)
        foreach (var n in nodes)
            if (n is FunctionNode fn)
                functions[fn.Name] = fn;
        symbols.GetOrAdd("__tmp");

        int frameSize = symbols.Count;

        // (Frame layout comments removed — user prefers cleaner output)

        // Initialize frame base from current SP for top-level execution.
        sb.AppendLine("LDX SP ; initialize frame base from SP (callers may set X before calls)");

        // Emit top-level statements inside an infinite main loop, then emit
        // function definitions.
        sb.AppendLine("main_loop:");
        for (int i = 0; i < nodes.Count; i++)
        {
            var n = nodes[i];
            if (n is FunctionNode) continue;

            // If this is a top-level assign that we decided to elide, skip emitting it entirely
            // (we'll push immediates at call sites instead of storing to a variable).
            if (n is AssignNode assign && assign.Expr is NumberNode && elideImmediates.ContainsKey(assign.Name))
            {
                continue;
            }

            // Emit top-level statements using the symbols table so library-backed
            // multi-byte ops can be used. For top-level `return` we keep the
            // previous behavior (leave value in A, no RTS).
            if (n is ReturnNode)
                Emit(n);
            else
                EmitWithSymbols(n, symbols);
        }

        // Merge any label with its following instruction and align the following
        // instruction lines to the same column across the entire output.
        string assembled = sb.ToString();
        var lines = assembled.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None).ToList();

        for (int i = 0; i < lines.Count; i++)
        {
            string lineTrim = lines[i].TrimEnd();
            if (string.IsNullOrWhiteSpace(lineTrim)) continue;
            string lineLeftTrim = lineTrim.TrimStart();
            // match label lines that end with ':'
            if (lineLeftTrim.EndsWith(":"))
            {
                // find next non-empty line
                int j = i + 1;
                while (j < lines.Count && string.IsNullOrWhiteSpace(lines[j])) j++;
                if (j >= lines.Count) break;
                string nextTrim = lines[j].TrimStart();
                // if next line is not a comment or another label, merge it
                if (!nextTrim.StartsWith(";") && !nextTrim.EndsWith(":"))
                {
                    // extract label part up to colon
                    string labelPart = lineLeftTrim;
                    int colonIdx = labelPart.IndexOf(':');
                    if (colonIdx >= 0)
                        labelPart = labelPart.Substring(0, colonIdx + 1);

                    // merge label and the instruction
                    lines[i] = labelPart + " " + nextTrim;
                    // remove the original next line so we don't leave a blank
                    lines.RemoveAt(j);

                    int instrPos = labelPart.Length + 1; // column where instruction starts

                    // indent subsequent lines until a blank line or next label
                    for (int k = j; k < lines.Count; k++)
                    {
                        string t = lines[k].TrimStart();
                        if (string.IsNullOrEmpty(t)) break;
                        if (t.EndsWith(":")) break;
                        if (t.StartsWith(";")) continue; // keep comments flush
                        lines[k] = new string(' ', instrPos) + t;
                    }
                }
            }
        }

        assembled = string.Join("\n", lines);
        // Update the string builder with the modified assembly
        sb = new StringBuilder(assembled);

        sb.AppendLine("JMP main_loop");

        foreach (var n in nodes)
        {
            if (n is FunctionNode fn)
                EmitFunction(fn);
        }

        return sb.ToString();
    }

    private void EmitFunction(FunctionNode fn)
    {
        var localSymbols = new SymbolTable();

        for (int i = 0; i < fn.Params.Count; i++)
            localSymbols.GetOrAdd(fn.Params[i]);

        foreach (var n in fn.Body)
            RegisterSymbols(n, localSymbols);

        localSymbols.GetOrAdd("__tmp");

        sb.AppendLine($"{fn.Name}:");
        sb.AppendLine("LDX SP ; set frame base from SP (callee)");
        sb.AppendLine(";; Function frame layout (SP-relative)");
        for (int i = 0; i < fn.Params.Count; i++)
        {
            int off = fn.Params.Count + 2 - i; // account for reserved __tmp at SP-1
            sb.AppendLine($";; SP-{off} => {fn.Params[i]}");
        }
        sb.AppendLine(";; SP-1 => __tmp");
        sb.AppendLine(";; Local frame (offset -> name)");
        foreach (var kv in localSymbols.GetAll())
        {
            if (fn.Params.Contains(kv.Key)) continue;
            if (kv.Key == "__tmp") continue; // __tmp already shown as SP-1
            sb.AppendLine($";; 0x{kv.Value:X2} => {kv.Key}");
        }

        // Allocate local slot(s) (__tmp) on the stack so SP-relative locals exist at fixed offsets.
        // Push a zero to reserve __tmp at SP-1.
        sb.AppendLine("LDA #0x00");
        sb.AppendLine("PSHA");

        // Load parameters from caller stack frame using SP-relative negative offsets
        // (avoid popping; access arguments at fixed negative offsets from SP)
        for (int i = 0; i < fn.Params.Count; i++)
        {
            int stackOffset = fn.Params.Count + 2 - i; // account for reserved __tmp at SP-1
            string neg = $"{stackOffset:X2}";
            int off = localSymbols.GetOrAdd(fn.Params[i]);
            sb.AppendLine($"LDA (SP-0x{neg}) ; load param {fn.Params[i]}");
            if (off >= 0 && off < 16)
            {
                // store low byte into virtual byte register; multi-byte values
                // are represented across consecutive ?b registers and library
                // routines operate on them when needed.
                sb.AppendLine($"STA ?b{off} ; {fn.Params[i]}");
            }
            else
                sb.AppendLine($"STA (0x{off:X4},X) ; {fn.Params[i]}");
        }

        foreach (var n in fn.Body)
            EmitWithSymbols(n, localSymbols);
    }

    private void RegisterSymbols(AstNode node, SymbolTable symbolsLocal)
    {
        if (node is DeclarationNode d)
        {
            symbolsLocal.GetOrAdd(d.Name, d.Type);
            return;
        }
        if (node is AssignNode a)
        {
            symbolsLocal.GetOrAdd(a.Name);
            RegisterSymbols(a.Expr, symbolsLocal);
        }
        else if (node is ReturnNode r)
        {
            RegisterSymbols(r.Expr, symbolsLocal);
        }
        else if (node is VarNode v)
        {
            symbolsLocal.GetOrAdd(v.Name);
        }
        else if (node is BinOpNode b)
        {
            RegisterSymbols(b.Left, symbolsLocal);
            RegisterSymbols(b.Right, symbolsLocal);
        }
        else if (node is CallNode call)
        {
            foreach (var arg in call.Args)
                RegisterSymbols(arg, symbolsLocal);
        }
        else if (node is NumberNode)
        {
            // nothing
        }
    }

    private void EmitWithSymbols(AstNode node, SymbolTable symbolsLocal)
    {
        if (node is AssignNode a)
        {
            int offset = symbolsLocal.GetOrAdd(a.Name);

            // Special-case: RHS is a BinOp of two virtual-register vars and
            // destination is also a virtual 32-bit register -> emit library
            // add directly into destination register (avoid clobbering sources).
            if (UseVRegLibrary && a.Expr is BinOpNode bin && bin.Left is VarNode lvn && bin.Right is VarNode rvn)
            {
                int dstOff = offset;
                int lOff = symbolsLocal.GetOrAdd(lvn.Name);
                int rOff = symbolsLocal.GetOrAdd(rvn.Name);
                var dstType = symbolsLocal.GetType(a.Name);
                var lType = symbolsLocal.GetType(lvn.Name);
                var rType = symbolsLocal.GetType(rvn.Name);

                if (dstOff >= 0 && dstOff < 16 && lOff >= 0 && lOff < 16 && rOff >= 0 && rOff < 16
                    && dstType == VarType.U32 && lType == VarType.U32 && rType == VarType.U32 && bin.Op == "+")
                {
                    int dstIdx = dstOff / 4;
                    int lidx = lOff / 4;
                    int ridx = rOff / 4;
                    sb.AppendLine($"JSR ?add32_l{dstIdx}_l{lidx}_l{ridx} ; l{dstIdx} <- l{lidx} + l{ridx}");
                    // Destination is a virtual register; library routine wrote full value into it.
                    return;
                }
            }

            // If assigning a numeric immediate to a multi-byte variable,
            // emit per-byte stores instead of trying to load a large
            // immediate into A (A is 8-bit).
            if (a.Expr is NumberNode nn)
            {
                var dstType = symbolsLocal.GetType(a.Name);
                int val = nn.Value;
                if (dstType == VarType.U16)
                {
                    int b0 = val & 0xFF;
                    int b1 = (val >> 8) & 0xFF;
                    if (offset >= 0 && offset < 16)
                    {
                        sb.AppendLine($"LDA #0x{b0:X2}");
                        sb.AppendLine($"STA ?b{offset} ; {a.Name} (low)");
                        sb.AppendLine($"LDA #0x{b1:X2}");
                        sb.AppendLine($"STA ?b{offset + 1} ; {a.Name} (high)");
                        return;
                    }
                    else
                    {
                        sb.AppendLine($"LDA #0x{b0:X2}");
                        sb.AppendLine($"STA (0x{offset:X4},X) ; {a.Name} (low)");
                        sb.AppendLine($"LDA #0x{b1:X2}");
                        sb.AppendLine($"STA (0x{(offset + 1):X4},X) ; {a.Name} (high)");
                        return;
                    }
                }
                else if (dstType == VarType.U32)
                {
                    int b0 = val & 0xFF;
                    int b1 = (val >> 8) & 0xFF;
                    int b2 = (val >> 16) & 0xFF;
                    int b3 = (val >> 24) & 0xFF;
                    if (offset >= 0 && offset < 16)
                    {
                        sb.AppendLine($"LDA #0x{b0:X2}");
                        sb.AppendLine($"STA ?b{offset} ; {a.Name} (b0)");
                        sb.AppendLine($"LDA #0x{b1:X2}");
                        sb.AppendLine($"STA ?b{offset + 1} ; {a.Name} (b1)");
                        sb.AppendLine($"LDA #0x{b2:X2}");
                        sb.AppendLine($"STA ?b{offset + 2} ; {a.Name} (b2)");
                        sb.AppendLine($"LDA #0x{b3:X2}");
                        sb.AppendLine($"STA ?b{offset + 3} ; {a.Name} (b3)");
                        return;
                    }
                    else
                    {
                        sb.AppendLine($"LDA #0x{b0:X2}");
                        sb.AppendLine($"STA (0x{offset:X4},X) ; {a.Name} (b0)");
                        sb.AppendLine($"LDA #0x{b1:X2}");
                        sb.AppendLine($"STA (0x{(offset + 1):X4},X) ; {a.Name} (b1)");
                        sb.AppendLine($"LDA #0x{b2:X2}");
                        sb.AppendLine($"STA (0x{(offset + 2):X4},X) ; {a.Name} (b2)");
                        sb.AppendLine($"LDA #0x{b3:X2}");
                        sb.AppendLine($"STA (0x{(offset + 3):X4},X) ; {a.Name} (b3)");
                        return;
                    }
                }
            }

            // Special-case: rhs is a virtual-register variable and both sides are
            // virtual 32-bit registers -> emit library mov32 to move whole value.
            if (UseVRegLibrary && a.Expr is VarNode srcVar)
            {
                int dstOff = offset;
                int srcOff = symbolsLocal.GetOrAdd(srcVar.Name);
                var dstType = symbolsLocal.GetType(a.Name);
                var srcType = symbolsLocal.GetType(srcVar.Name);

                // If source is memory and destination is a virtual 32-bit register,
                // load from memory into the virtual register using library routine.
                if (UseVRegLibrary && srcOff >= 16 && dstOff >= 0 && dstOff < 16 && dstType == VarType.U32)
                {
                    int dstIdx = dstOff / 4;
                    EmitSetXToOffset(srcOff);
                    sb.AppendLine($"JSR ?load32_l{dstIdx} ; load [SP+{srcOff}] -> l{dstIdx}");
                    return;
                }

                if (dstOff >= 0 && dstOff < 16 && srcOff >= 0 && srcOff < 16 &&
                    dstType == VarType.U32 && srcType == VarType.U32)
                {
                    int dstIdx = dstOff / 4;
                    int srcIdx = srcOff / 4;
                    sb.AppendLine($"JSR ?mov32_l{dstIdx}_l{srcIdx} ; mov32 {a.Name} <- {srcVar.Name}");
                    return;
                }

                // If destination is memory (SP-relative) and source is virtual 32-bit,
                // emit store32 library call: set X to destination address then JSR store.
                if (dstOff >= 16 && srcOff >= 0 && srcOff < 16 && srcType == VarType.U32)
                {
                    int srcIdx = srcOff / 4;
                    EmitSetXToOffset(dstOff);
                    sb.AppendLine($"JSR ?store32_l{srcIdx} ; store l{srcIdx} -> [X]");
                    return;
                }
            }

            // Default path: evaluate RHS and store low byte into byte virtual reg or memory.
            EmitExprWithSymbols(a.Expr, symbolsLocal);

            if (offset >= 0 && offset < 16)
            {
                sb.AppendLine($"STA ?b{offset} ; {a.Name}");
            }
            else
                sb.AppendLine($"STA (0x{offset:X4},X) ; {a.Name}");
        }
        else if (node is ReturnNode r)
        {
            EmitExprWithSymbols(r.Expr, symbolsLocal);
            sb.AppendLine("RTS");
        }
        else if (node is CallNode c)
        {
            EmitCall(c, symbolsLocal);
            sb.AppendLine($"JSR {c.Name}");
        }
    }

    private void EmitExprWithSymbols(AstNode node, SymbolTable symbolsLocal)
    {
        if (node is NumberNode n)
        {
            string imm = n.Value < 0 ? $"-0x{(-n.Value):X2}" : $"0x{n.Value:X2}";
            sb.AppendLine($"LDA #{imm}");
        }
        else if (node is VarNode v)
        {
            int offset = symbolsLocal.GetOrAdd(v.Name);
            if (offset >= 0 && offset < 16)
                sb.AppendLine($"LDA ?b{offset} ; {v.Name}");
            else
                sb.AppendLine($"LDA (0x{offset:X4},X) ; {v.Name}");
        }
        else if (node is BinOpNode b)
        {
            // Fast path: both operands are local virtual registers -> emit short form
            if (b.Left is VarNode lv && b.Right is VarNode rv)
            {
                int loff = symbolsLocal.GetOrAdd(lv.Name);
                int roff = symbolsLocal.GetOrAdd(rv.Name);
                if (loff >= 0 && loff < 16 && roff >= 0 && roff < 16)
                {
                    var lt = symbolsLocal.GetType(lv.Name);
                    var rt = symbolsLocal.GetType(rv.Name);

                    // 8-bit fast path (inline ADDA)
                    if (lt == VarType.U8 && rt == VarType.U8)
                    {
                        sb.AppendLine($"LDA ?b{loff} ; {lv.Name}");
                        if (b.Op == "+")
                            sb.AppendLine($"ADDA ?b{roff} ; {rv.Name}");
                        else if (b.Op == "-")
                            sb.AppendLine("/* Subtraction not implemented using register fast path */");
                        return;
                    }

                    // 16-bit: call library routine to do w_dest <= w_left + w_right
                    if (UseVRegLibrary && lt == VarType.U16 && rt == VarType.U16 && b.Op == "+")
                    {
                        int lidx = loff / 2;
                        int ridx = roff / 2;
                        sb.AppendLine($"JSR ?add16_w{lidx}_w{lidx}_w{ridx}");
                        // result placed in w{lidx}; return low byte in A
                        sb.AppendLine($"LDA ?b{lidx*2} ; low byte of result w{lidx}");
                        return;
                    }

                    // 32-bit: call library routine to do l_dest <= l_left + l_right
                    if (UseVRegLibrary && lt == VarType.U32 && rt == VarType.U32 && b.Op == "+")
                    {
                        int lidx = loff / 4;
                        int ridx = roff / 4;
                        sb.AppendLine($"JSR ?add32_l{lidx}_l{lidx}_l{ridx}");
                        // result low byte into A
                        sb.AppendLine($"LDA ?b{lidx*4} ; low byte of result l{lidx}");
                        return;
                    }
                }
            }

            EmitExprWithSymbols(b.Left, symbolsLocal);
            sb.AppendLine("PSHA");
            EmitExprWithSymbols(b.Right, symbolsLocal);
            int tmp = symbolsLocal.GetOrAdd("__tmp");
            sb.AppendLine($"STA (0x{tmp:X4},X) ; __tmp");

            sb.AppendLine("POPA");

            if (b.Op == "+")
                sb.AppendLine($"ADDA (0x{tmp:X4},X)");
            else if (b.Op == "-")
                sb.AppendLine("/* Subtraction not implemented using stack yet */");
        }
        else if (node is CallNode c)
        {
            EmitCall(c, symbolsLocal);
            sb.AppendLine($"JSR {c.Name}");
        }
    }

    private void RegisterSymbols(AstNode node)
    {
        if (node is DeclarationNode d)
        {
            symbols.GetOrAdd(d.Name, d.Type);
            return;
        }
        if (node is AssignNode a)
        {
            symbols.GetOrAdd(a.Name);
            RegisterSymbols(a.Expr);
        }
        else if (node is ReturnNode r)
        {
            RegisterSymbols(r.Expr);
        }
        else if (node is VarNode v)
        {
            symbols.GetOrAdd(v.Name);
        }
        else if (node is BinOpNode b)
        {
            RegisterSymbols(b.Left);
            RegisterSymbols(b.Right);
        }
        else if (node is NumberNode)
        {
            // nothing to register
        }
    }

    private void Emit(AstNode node)
    {
        if (node is AssignNode a)
        {
            int offset = symbols.GetOrAdd(a.Name);

            EmitExpr(a.Expr);

            if (offset >= 0 && offset < 16)
            {
                sb.AppendLine($"STA ?b{offset} ; {a.Name}");
            }
            else
                sb.AppendLine($"STA (0x{offset:X4},X) ; {a.Name}");
        }
        else if (node is ReturnNode r)
        {
            // Top-level return: just compute the expression and leave value in A.
            // Do NOT emit RTS here — functions emit RTS via EmitWithSymbols.
            EmitExpr(r.Expr);
        }
        else if (node is CallNode c)
        {
            EmitCall(c, symbols);
            sb.AppendLine($"JSR {c.Name}");
        }
    }

    private void EmitExpr(AstNode node)
    {
        if (node is NumberNode n)
        {
            string imm;
            if (n.Value < 0)
                imm = $"-0x{(-n.Value):X2}";
            else
                imm = $"0x{n.Value:X2}";

            sb.AppendLine($"LDA #{imm}");
        }
        else if (node is VarNode v)
        {
            int offset = symbols.GetOrAdd(v.Name);
            if (offset >= 0 && offset < 16)
                sb.AppendLine($"LDA ?b{offset} ; {v.Name}");
            else
                sb.AppendLine($"LDA (0x{offset:X4},X) ; {v.Name}");
        }
        else if (node is CallNode c)
        {
            EmitCall(c, symbols);
            sb.AppendLine($"JSR {c.Name}");
            // result is returned in A
        }
        else if (node is BinOpNode b)
        {
            // Fast path: both operands are top-level virtual registers
            if (b.Left is VarNode lv && b.Right is VarNode rv)
            {
                int loff = symbols.GetOrAdd(lv.Name);
                int roff = symbols.GetOrAdd(rv.Name);
                if (loff >= 0 && loff < 16 && roff >= 0 && roff < 16)
                {
                    var lt = symbols.GetType(lv.Name);
                    var rt = symbols.GetType(rv.Name);
                    if (lt == VarType.U8 && rt == VarType.U8)
                    {
                        sb.AppendLine($"LDA ?b{loff} ; {lv.Name}");
                        if (b.Op == "+")
                            sb.AppendLine($"ADDA ?b{roff} ; {rv.Name}");
                        else if (b.Op == "-")
                            sb.AppendLine("/* Subtraction not implemented using register fast path */");
                        return;
                    }
                }
            }

            // Push left operand, evaluate right, store right to a temporary
            // memory slot, pop left into A, then add memory to A.
            EmitExpr(b.Left);
            sb.AppendLine("PSHA");
            EmitExpr(b.Right);
            int tmp = symbols.GetOrAdd("__tmp");
            sb.AppendLine($"STA (0x{tmp:X4},X) ; __tmp");

            sb.AppendLine("POPA");

            if (b.Op == "+")
                sb.AppendLine($"ADDA (0x{tmp:X4},X)");
            else if (b.Op == "-")
                sb.AppendLine("/* Subtraction not implemented using stack yet */");
        }
    }

    private int CountVarUses(AstNode node, string name)
    {
        if (node == null) return 0;
        if (node is VarNode v) return v.Name == name ? 1 : 0;
        if (node is AssignNode a) return CountVarUses(a.Expr, name);
        if (node is ReturnNode r) return CountVarUses(r.Expr, name);
        if (node is NumberNode) return 0;
        if (node is BinOpNode b) return CountVarUses(b.Left, name) + CountVarUses(b.Right, name);
        if (node is CallNode c)
        {
            int sum = 0;
            foreach (var arg in c.Args) sum += CountVarUses(arg, name);
            return sum;
        }
        return 0;
    }

    private bool ArgIsVarName(AstNode arg, string name)
    {
        return arg is VarNode v && v.Name == name;
    }
        private void EmitCall(CallNode c, SymbolTable symbolsLocal)
        {
        // Evaluate args left-to-right: record immediates, store non-immediates to temps
        var args = c.Args;
        var immediateVals = new (bool isImm, int val)[args.Count];
        for (int i = 0; i < args.Count; i++)
        {
            var arg = args[i];
            if (arg is NumberNode nn)
            {
                immediateVals[i] = (true, nn.Value);
                continue;
            }
            if (arg is VarNode vn && elideImmediates.TryGetValue(vn.Name, out var imm))
            {
                immediateVals[i] = (true, imm);
                continue;
            }

            // non-immediate: evaluate and store to temp
            if (symbolsLocal == symbols)
                EmitExpr(arg);
            else
                EmitExprWithSymbols(arg, symbolsLocal);

            string tmpName = $"__calltmp_{i}";
            int tmpOff = symbolsLocal.GetOrAdd(tmpName);
            if (tmpOff >= 0 && tmpOff < 16)
                sb.AppendLine($"STA ?b{tmpOff} ; {tmpName}");
            else
                sb.AppendLine($"STA (0x{tmpOff:X4},X) ; {tmpName}");
        }

        // Push args in reverse order so the first emitted push is the first argument's value
        for (int i = args.Count - 1; i >= 0; i--)
        {
            if (immediateVals[i].isImm)
            {
                int imm = immediateVals[i].val;
                string imms = imm < 0 ? $"-0x{(-imm):X2}" : $"0x{imm:X2}";
                sb.AppendLine($"LDA #{imms}");
                sb.AppendLine("PSHA");
                continue;
            }

            string tmpName = $"__calltmp_{i}";
            int tmpOff = symbolsLocal.GetOrAdd(tmpName);
            if (tmpOff >= 0 && tmpOff < 16)
                sb.AppendLine($"LDA ?b{tmpOff} ; {tmpName}");
            else
                sb.AppendLine($"LDA (0x{tmpOff:X4},X) ; {tmpName}");
            sb.AppendLine("PSHA");
        }

        // Caller should not set X; callee initializes its own frame base.
    }
    
    // Emit code to set X = SP + offset (advance X from SP by `offset` bytes).
    // This uses repeated INCX instructions; acceptable for small offsets.
    private void EmitSetXToOffset(int offset)
    {
        sb.AppendLine("LDX SP");
        // Group INCX in blocks of 4 to reduce emitted instruction count lines.
        int q = offset / 4;
        int r = offset % 4;
        for (int i = 0; i < q; i++)
        {
            sb.AppendLine("INCX");
            sb.AppendLine("INCX");
            sb.AppendLine("INCX");
            sb.AppendLine("INCX");
        }
        for (int i = 0; i < r; i++)
            sb.AppendLine("INCX");
    }
    
    
    
}
