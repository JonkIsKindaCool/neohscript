package hscript.lexer;

enum TokenKind {
	TInt(i:Int);
	TFloat(f:Float);
	TString(s:String, ?singleQuote:Bool);
	TIdent(id:String);
	TKeyword(keyword:Keyword);

	TPlus; // +
	TMinus; // -
	TStar; // *
	TSlash; // /
	TPercent; // %

	TPlusPlus; // ++
	TMinusMinus; // --

	TAssign; // =
	TPlusAssign; // +=
	TMinusAssign; // -=
	TStarAssign; // *=
	TSlashAssign; // /=
	TPercentAssign; // %=

	TEqual; // ==
	TNotEqual; // !=

	TLess; // <
	TLessEqual; // <=
	TGreater; // >
	TGreaterEqual; // >=

	TAnd; // &&
	TOr; // ||
	TNot; // !

	TBitAnd; // &
	TBitOr; // |
	TBitXor; // ^
	TBitNot; // ~

	TShiftLeft; // <<
	TShiftRight; // >>

	TAndAssign; // &=
	TOrAssign; // |=
	TXorAssign; // ^=

	TInterval;

	TQuestion; // ?
	TColon; // :
	TArrow; // ->

	TDot; // .
	TComma; // ,
	TSemicolon; // ;

	TLParen; // (
	TRParen; // )
	TLBrace; // {
	TRBrace; // }
	TLBracket; // [
	TRBracket; // ]

	TEof;
}

enum Keyword {
	VAR;
	FINAL;
	STATIC;
	FUNCTION;
	CLASS;
	INTERFACE;
	ENUM;
	ABSTRACT;
	TYPEDEF;
	IN;
	EXTENDS;
	IMPLEMENTS;
	NEW;
	IF;
	ELSE;
	WHILE;
	DO;
	FOR;
	SWITCH;
	CASE;
	DEFAULT;
	BREAK;
	CONTINUE;
	RETURN;
	THROW;
	TRY;
	CATCH;
	PUBLIC;
	PRIVATE;
	PROTECTED;
	INLINE;
	OVERRIDE;
	DYNAMIC;
	EXTERN;
	TRUE;
	FALSE;
	NULL;
	IMPORT;
	USING;
	PACKAGE;
	UNTYPED;
	CAST;
	THIS;
	SUPER;
	MACRO;
}
