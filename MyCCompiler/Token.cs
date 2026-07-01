public enum TokenType
{
    Identifier,
    Number,

    Plus,
    Minus,
    Equals,
    Semicolon,
    LParen,
    RParen,
    Comma,
    LBrace,
    RBrace,
    Func,

    Return,

    End
}

public class Token
{
    public TokenType Type;
    public string Text;

    public Token(TokenType type, string text)
    {
        Type = type;
        Text = text;
    }
}