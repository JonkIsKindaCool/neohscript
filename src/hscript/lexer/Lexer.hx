package hscript.lexer;

using StringTools;

class Lexer {
	public static function tokenify(src:String):Array<Token> {
		final tokens:Array<Token> = [];
		var pos:Int = 0;
		var line:Int = 1;
		var length:Int = src.length;

		inline function peek(offset:Int = 0):Int {
			return (pos + offset < length) ? src.fastCodeAt(pos + offset) : -1;
		}

		inline function advance():Int {
			return src.fastCodeAt(pos++);
		}

		inline function add(kind:TokenKind, start:Int, end:Int) {
			tokens.push({
				start: start,
				end: end,
				line: line,
				kind: kind
			});
		}

		inline function isDigit(c:Int):Bool
			return c >= '0'.code && c <= '9'.code;
		inline function isAlpha(c:Int):Bool
			return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || c == '_'.code;
		inline function isAlnum(c:Int):Bool
			return isAlpha(c) || isDigit(c);

		inline function isHex(c:Int):Bool {
			return (c >= '0'.code && c <= '9'.code) || (c >= 'a'.code && c <= 'f'.code) || (c >= 'A'.code && c <= 'F'.code);
		}

		while (pos < length) {
			var start:Int = pos;
			var c:Int = advance();

			switch (c) {
				case ' '.code, '\t'.code, '\r'.code:
					continue;
				case '\n'.code:
					line++;
					continue;

				case '0'.code, '1'.code, '2'.code, '3'.code, '4'.code, '5'.code, '6'.code, '7'.code, '8'.code, '9'.code:
					var intValue:Int = 0;
					var floatValue:Float = 0;
					var isFloat:Bool = false;

					if (c == '0'.code && (peek() == 'x'.code || peek() == 'X'.code)) {
						advance();

						while (isHex(peek())) {
							var h = advance();
							intValue <<= 4;

							if (h >= '0'.code && h <= '9'.code)
								intValue += h - '0'.code;
							else if (h >= 'a'.code)
								intValue += h - 'a'.code + 10;
							else
								intValue += h - 'A'.code + 10;
						}

						add(TInt(intValue), start, pos);
					} else {
						intValue = c - '0'.code;

						while (isDigit(peek())) {
							intValue = intValue * 10 + (advance() - '0'.code);
						}

						if (peek() == '.'.code && isDigit(peek(1))) {
							isFloat = true;
							advance();

							floatValue = intValue;
							var factor:Float = 0.1;

							while (isDigit(peek())) {
								floatValue += (advance() - '0'.code) * factor;
								factor *= 0.1;
							}

							add(TFloat(floatValue), start, pos);
						} else {
							add(TInt(intValue), start, pos);
						}
					}
				case _ if (isAlpha(c)):
					while (isAlnum(peek()))
						advance();
					var str:String = src.substring(start, pos);
					add(TIdent(str), start, pos);

				case '"'.code:
					while (peek() != '"'.code && peek() != -1) {
						if (peek() == '\n'.code)
							line++;
						advance();
					}
					advance();

					var str:String = src.substring(start + 1, pos - 1);
					add(TString(str), start, pos);

				case '+'.code:
					switch (peek()) {
						case '+'.code:
							advance();
							add(TPlusPlus, start, pos);
						case '='.code:
							advance();
							add(TPlusAssign, start, pos);
						default: add(TPlus, start, pos);
					}

				case '-'.code:
					switch (peek()) {
						case '-'.code:
							advance();
							add(TMinusMinus, start, pos);
						case '='.code:
							advance();
							add(TMinusAssign, start, pos);
						case '>'.code:
							advance();
							add(TArrow, start, pos);
						default: add(TMinus, start, pos);
					}

				case '*'.code:
					if (peek() == '='.code) {
						advance();
						add(TStarAssign, start, pos);
					} else
						add(TStar, start, pos);

				case '/'.code:
					switch (peek()) {
						case '='.code:
							advance();
							add(TSlashAssign, start, pos);

						case '/'.code:
							while (peek() != '\n'.code && peek() != -1)
								advance();

						default:
							add(TSlash, start, pos);
					}

				case '%'.code:
					if (peek() == '='.code) {
						advance();
						add(TPercentAssign, start, pos);
					} else
						add(TPercent, start, pos);

				case '='.code:
					if (peek() == '='.code) {
						advance();
						add(TEqual, start, pos);
					} else
						add(TAssign, start, pos);

				case '!'.code:
					if (peek() == '='.code) {
						advance();
						add(TNotEqual, start, pos);
					} else
						add(TNot, start, pos);

				case '<'.code:
					if (peek() == '<'.code) {
						advance();
						add(TShiftLeft, start, pos);
					} else if (peek() == '='.code) {
						advance();
						add(TLessEqual, start, pos);
					} else
						add(TLess, start, pos);

				case '>'.code:
					if (peek() == '>'.code) {
						advance();
						add(TShiftRight, start, pos);
					} else if (peek() == '='.code) {
						advance();
						add(TGreaterEqual, start, pos);
					} else
						add(TGreater, start, pos);

				case '&'.code:
					if (peek() == '&'.code) {
						advance();
						add(TAnd, start, pos);
					} else if (peek() == '='.code) {
						advance();
						add(TAndAssign, start, pos);
					} else
						add(TBitAnd, start, pos);

				case '|'.code:
					if (peek() == '|'.code) {
						advance();
						add(TOr, start, pos);
					} else if (peek() == '='.code) {
						advance();
						add(TOrAssign, start, pos);
					} else
						add(TBitOr, start, pos);

				case '^'.code:
					if (peek() == '='.code) {
						advance();
						add(TXorAssign, start, pos);
					} else
						add(TBitXor, start, pos);

				case '~'.code:
					add(TBitNot, start, pos);

				case '?'.code:
					add(TQuestion, start, pos);
				case ':'.code:
					add(TColon, start, pos);

				case '.'.code:
					add(TDot, start, pos);
				case ','.code:
					add(TComma, start, pos);
				case ';'.code:
					add(TSemicolon, start, pos);

				case '('.code:
					add(TLParen, start, pos);
				case ')'.code:
					add(TRParen, start, pos);
				case '{'.code:
					add(TLBrace, start, pos);
				case '}'.code:
					add(TRBrace, start, pos);
				case '['.code:
					add(TLBracket, start, pos);
				case ']'.code:
					add(TRBracket, start, pos);

				default:
			}
		}

		tokens.push({
			start: pos,
			end: pos,
			line: line,
			kind: TEof
		});

		return tokens;
	}
}
