using System;
using System.Collections.Generic;

public class Parser
{
    private List<Token> tokens;
    private int pos;

    public Parser(List<Token> t)
    {
        tokens = t;
    }

    private Token Peek() => tokens[pos];
    private Token Next() => tokens[pos++];

    public List<AstNode> Parse()
    {
        List<AstNode> nodes = new();

        while (Peek().Type != TokenType.End)
        {
            if (Peek().Type == TokenType.Func)
            {
                nodes.Add(ParseFunction());
            }
            else
            {
                nodes.Add(ParseStatement());
            }
        }

        return nodes;
    }

    private AstNode ParseFunction()
    {
        Next(); // consume 'func'
        var id = Next();
        if (id.Type != TokenType.Identifier)
            throw new Exception("Expected function name");

        Expect(TokenType.LParen);
        var ps = new List<string>();
        if (Peek().Type != TokenType.RParen)
        {
            var p = Next();
            if (p.Type != TokenType.Identifier) throw new Exception("Expected param");
            ps.Add(p.Text);
            while (Peek().Type == TokenType.Comma)
            {
                Next();
                p = Next();
                if (p.Type != TokenType.Identifier) throw new Exception("Expected param");
                ps.Add(p.Text);
            }
        }
        Expect(TokenType.RParen);

        Expect(TokenType.LBrace);
        var body = new List<AstNode>();
        while (Peek().Type != TokenType.RBrace)
            body.Add(ParseStatement());
        Expect(TokenType.RBrace);

        return new FunctionNode(id.Text, ps, body);
    }

    private AstNode ParseStatement()
    {
        if (Peek().Type == TokenType.Return)
        {
            Next();
            var expr = ParseExpression();
            Expect(TokenType.Semicolon);
            return new ReturnNode(expr);
        }

        // Could be a typed declaration like: uint8_t a;
        var first = Next();
        if (first.Type != TokenType.Identifier)
            throw new Exception("Expected identifier");

        // declaration if first token is a known type and followed by an identifier
        if ((first.Text == "uint8_t" || first.Text == "uint16_t" || first.Text == "uint32_t") && Peek().Type == TokenType.Identifier)
        {
            var nameTok = Next();
            var type = first.Text == "uint8_t" ? VarType.U8 : first.Text == "uint16_t" ? VarType.U16 : VarType.U32;
            Expect(TokenType.Semicolon);
            return new DeclarationNode(type, nameTok.Text);
        }

        // otherwise assignment
        var id = first;
        Expect(TokenType.Equals);

        var expr2 = ParseExpression();
        Expect(TokenType.Semicolon);

        return new AssignNode(id.Text, expr2);
    }

    private AstNode ParseExpression()
    {
        var left = ParseTerm();

        while (Peek().Type == TokenType.Plus ||
               Peek().Type == TokenType.Minus)
        {
            var op = Next().Text;
            var right = ParseTerm();
            left = new BinOpNode(left, op, right);
        }

        return left;
    }

    private AstNode ParseTerm()
    {
        var t = Next();

        if (t.Type == TokenType.Number)
        {
            string txt = t.Text;
            if (txt.StartsWith("0x") || txt.StartsWith("0X"))
                return new NumberNode(Convert.ToInt32(txt.Substring(2), 16));
            return new NumberNode(int.Parse(txt));
        }

        if (t.Type == TokenType.Identifier)
        {
            // function call?
            if (Peek().Type == TokenType.LParen)
            {
                Next(); // consume '('
                var args = new List<AstNode>();
                if (Peek().Type != TokenType.RParen)
                {
                    args.Add(ParseExpression());
                    while (Peek().Type == TokenType.Comma)
                    {
                        Next();
                        args.Add(ParseExpression());
                    }
                }
                Expect(TokenType.RParen);
                return new CallNode(t.Text, args);
            }

            return new VarNode(t.Text);
        }

        throw new Exception("Bad expression");
    }

    private void Expect(TokenType type)
    {
        if (Peek().Type != type)
            throw new Exception("Expected " + type);
        Next();
    }
}