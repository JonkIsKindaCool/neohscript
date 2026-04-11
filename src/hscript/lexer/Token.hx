package hscript.lexer;

import hscript.lexer.TokenKind.Keyword;

@:structInit
class Token {
	public var start:Int;
	public var end:Int;
	public var line:Int;

	public var kind:TokenKind;

	public static function toLiteralString(kind:TokenKind):String {
		return switch (kind) {
			case TInt(i): '$i';
			case TFloat(f): '$f';
			case TString(s, true): "'" + s + "'"; 
			case TString(s, false) | TString(s, null): '"$s"';

			case TIdent(id): id;

			case TKeyword(k): keywordToString(k);

			case TPlus: "+";
			case TMinus: "-";
			case TStar: "*";
			case TSlash: "/";
			case TPercent: "%";

			case TPlusPlus: "++";
			case TMinusMinus: "--";

			case TAssign: "=";
			case TPlusAssign: "+=";
			case TMinusAssign: "-=";
			case TStarAssign: "*=";
			case TSlashAssign: "/=";
			case TPercentAssign: "%=";

			case TEqual: "==";
			case TNotEqual: "!=";

			case TLess: "<";
			case TLessEqual: "<=";
			case TGreater: ">";
			case TGreaterEqual: ">=";

			case TAnd: "&&";
			case TOr: "||";
			case TNot: "!";

			case TBitAnd: "&";
			case TBitOr: "|";
			case TBitXor: "^";
			case TBitNot: "~";

			case TShiftLeft: "<<";
			case TShiftRight: ">>";

			case TAndAssign: "&=";
			case TOrAssign: "|=";
			case TXorAssign: "^=";

			case TQuestion: "?";
			case TColon: ":";
			case TArrow: "->";

			case TDot: ".";
			case TComma: ",";
			case TSemicolon: ";";

			case TLParen: "(";
			case TRParen: ")";
			case TLBrace: "{";
			case TRBrace: "}";
			case TLBracket: "[";
			case TRBracket: "]";

			case TEof: "<EOF>";
		}
	}

	private static function keywordToString(k:Keyword):String {
		return switch (k) {
			case VAR: "var";
			case FINAL: "final";
			case STATIC: "static";
			case FUNCTION: "function";
			case CLASS: "class";
			case INTERFACE: "interface";
			case ENUM: "enum";
			case ABSTRACT: "abstract";
			case TYPEDEF: "typedef";
			case EXTENDS: "extends";
			case IMPLEMENTS: "implements";
			case NEW: "new";
			case IF: "if";
			case ELSE: "else";
			case WHILE: "while";
			case DO: "do";
			case FOR: "for";
			case SWITCH: "switch";
			case CASE: "case";
			case DEFAULT: "default";
			case BREAK: "break";
			case CONTINUE: "continue";
            case IN: "in";
			case RETURN: "return";
			case THROW: "throw";
			case TRY: "try";
			case CATCH: "catch";
			case PUBLIC: "public";
			case PRIVATE: "private";
			case PROTECTED: "protected";
			case INLINE: "inline";
			case OVERRIDE: "override";
			case DYNAMIC: "dynamic";
			case EXTERN: "extern";
			case TRUE: "true";
			case FALSE: "false";
			case NULL: "null";
			case IMPORT: "import";
			case USING: "using";
			case PACKAGE: "package";
			case UNTYPED: "untyped";
			case CAST: "cast";
			case THIS: "this";
			case SUPER: "super";
			case MACRO: "macro";
		}
	}
}
