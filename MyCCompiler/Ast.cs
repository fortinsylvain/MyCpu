public abstract class AstNode { }

public class NumberNode : AstNode
{
    public int Value;
    public NumberNode(int v) { Value = v; }
}

public class VarNode : AstNode
{
    public string Name;
    public VarNode(string n) { Name = n; }
}

public class BinOpNode : AstNode
{
    public AstNode Left;
    public AstNode Right;
    public string Op;

    public BinOpNode(AstNode l, string op, AstNode r)
    {
        Left = l;
        Op = op;
        Right = r;
    }
}

public class AssignNode : AstNode
{
    public string Name;
    public AstNode Expr;

    public AssignNode(string name, AstNode expr)
    {
        Name = name;
        Expr = expr;
    }
}

public class ReturnNode : AstNode
{
    public AstNode Expr;

    public ReturnNode(AstNode e)
    {
        Expr = e;
    }
}

public class FunctionNode : AstNode
{
    public string Name;
    public List<string> Params;
    public List<AstNode> Body;

    public FunctionNode(string name, List<string> ps, List<AstNode> body)
    {
        Name = name;
        Params = ps;
        Body = body;
    }
}

public class CallNode : AstNode
{
    public string Name;
    public List<AstNode> Args;

    public CallNode(string name, List<AstNode> args)
    {
        Name = name;
        Args = args;
    }
}

public class DeclarationNode : AstNode
{
    public string Name;
    public VarType Type;

    public DeclarationNode(VarType t, string name)
    {
        Type = t;
        Name = name;
    }
}