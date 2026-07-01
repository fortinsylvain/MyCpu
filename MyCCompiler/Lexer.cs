using System;
using System.Collections.Generic;

public class Lexer
{
    private string src;
    private int pos;

    public Lexer(string source)
    {
        src = source;
        pos = 0;
    }

    private char Peek()
    {
        if (pos >= src.Length) return '\0';
        return src[pos];
    }

    private char Next()
    {
        if (pos >= src.Length) return '\0';
        return src[pos++];
    }

    private bool IsHexDigit(char c)
    {
        if (c == '\0') return false;
        return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
    }

    public List<Token> Tokenize()
    {
        List<Token> tokens = new();

        while (true)
        {
            char c = Peek();

            if (c == '\0')
            {
                tokens.Add(new Token(TokenType.End, ""));
                break;
            }

            if (char.IsWhiteSpace(c))
            {
                Next();
                continue;
            }

            if (char.IsLetter(c) || c == '_')
            {
                string id = "";
                while (char.IsLetterOrDigit(Peek()) || Peek() == '_')
                    id += Next();

                if (id == "return")
                    tokens.Add(new Token(TokenType.Return, id));
                else if (id == "func")
                    tokens.Add(new Token(TokenType.Func, id));
                else
                    tokens.Add(new Token(TokenType.Identifier, id));

                continue;
            }

            if (char.IsDigit(c))
            {
                string num = "";
                // handle hex: 0x.....
                if (c == '0' && pos + 1 < src.Length && (src[pos + 1] == 'x' || src[pos + 1] == 'X'))
                {
                    // consume '0'
                    num += Next();
                    // consume 'x' or 'X'
                    num += Next();
                    while (IsHexDigit(Peek()))
                        num += Next();
                    tokens.Add(new Token(TokenType.Number, num));
                    continue;
                }

                while (char.IsDigit(Peek()))
                    num += Next();

                tokens.Add(new Token(TokenType.Number, num));
                continue;
            }

            switch (c)
            {
                case '/':
                    // handle comments: '//' line comments and '/* ... */' block comments
                    Next();
                    if (Peek() == '/')
                    {
                        // line comment - consume until end of line
                        Next();
                        while (Peek() != '\n' && Peek() != '\0') Next();
                        continue;
                    }
                    else if (Peek() == '*')
                    {
                        // block comment - consume until '*/'
                        Next();
                        while (true)
                        {
                            char p = Next();
                            if (p == '\0') break;
                            if (p == '*' && Peek() == '/') { Next(); break; }
                        }
                        continue;
                    }
                    else
                    {
                        // not a comment - treat as unknown for now
                        throw new Exception("Unknown char: /");
                    }

                case '+': Next(); tokens.Add(new Token(TokenType.Plus, "+")); break;
                case '-': Next(); tokens.Add(new Token(TokenType.Minus, "-")); break;
                case '=': Next(); tokens.Add(new Token(TokenType.Equals, "=")); break;
                case ';': Next(); tokens.Add(new Token(TokenType.Semicolon, ";")); break;
                case '(' : Next(); tokens.Add(new Token(TokenType.LParen, "(")); break;
                case ')' : Next(); tokens.Add(new Token(TokenType.RParen, ")")); break;
                case ',' : Next(); tokens.Add(new Token(TokenType.Comma, ",")); break;
                case '{' : Next(); tokens.Add(new Token(TokenType.LBrace, "{")); break;
                case '}' : Next(); tokens.Add(new Token(TokenType.RBrace, "}")); break;
                default:
                    throw new Exception("Unknown char: " + c);
            }
        }

        return tokens;
    }
}