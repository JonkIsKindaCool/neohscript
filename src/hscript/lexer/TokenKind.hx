package hscript.lexer;

enum TokenKind {
    TInt(i:Int);
    TFloat(f:Float);
    TString(s:String);
    TIdent(id:String);
    TKeyword(keyword:String);

    TPlus;        // +
    TMinus;       // -
    TStar;        // *
    TSlash;       // /
    TPercent;     // %

    TPlusPlus;    // ++
    TMinusMinus;  // --

    TAssign;          // =
    TPlusAssign;      // +=
    TMinusAssign;     // -=
    TStarAssign;      // *=
    TSlashAssign;     // /=
    TPercentAssign;   // %=

    TEqual;        // ==
    TNotEqual;     // !=

    TLess;         // <
    TLessEqual;    // <=
    TGreater;      // >
    TGreaterEqual; // >=

    TAnd;          // &&
    TOr;           // ||
    TNot;          // !

    TBitAnd;       // &
    TBitOr;        // |
    TBitXor;       // ^
    TBitNot;       // ~

    TShiftLeft;    // <<
    TShiftRight;   // >>

    TAndAssign;    // &=
    TOrAssign;     // |=
    TXorAssign;    // ^=

    TQuestion;     // ?
    TColon;        // :
    TArrow;        // ->

    TDot;          // .
    TComma;        // ,
    TSemicolon;    // ;

    TLParen;       // (
    TRParen;       // )
    TLBrace;       // {
    TRBrace;       // }
    TLBracket;     // [
    TRBracket;     // ]

    TEof;
}