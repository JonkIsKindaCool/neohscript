package hscript.ast;

import hscript.data.ObjectValue;
import hscript.data.FunctionArgument;
import hscript.data.AnonymousValue;
import hscript.data.Types;
import hscript.errors.HscriptException;
import haxe.macro.Expr;
import haxe.Exception;
import haxe.ds.GenericStack;
import hscript.ast.Span;
import hscript.ast.expressions.ExpressionKind;
import hscript.ast.expressions.Expression;
import hscript.lexer.Token;
import hscript.lexer.TokenKind;

class Parser {
	var tokens:Array<Token>;
	var pos:Int = 0;
	var current:Token;
	var file:String;

	public static final OP_PRECEDENCE:Map<Binop, Int> = [
		OpIn => 1,
		OpNullCoal => 2,
		OpAssign => 3,
		OpArrow => 3,
		OpBoolOr => 4,
		OpBoolAnd => 5,
		OpInterval => 6,
		OpEq => 7,
		OpNotEq => 7,
		OpGt => 7,
		OpLt => 7,
		OpGte => 7,
		OpLte => 7,
		OpOr => 8,
		OpAnd => 8,
		OpXor => 8,
		OpShl => 9,
		OpShr => 9,
		OpUShr => 9,
		OpAdd => 10,
		OpSub => 10,
		OpMult => 11,
		OpDiv => 11,
		OpMod => 11,
	];

	public function new() {}

	public function parse(tokens:Array<Token>, file:String = "<unnamed>"):Expression {
		this.tokens = tokens;
		this.pos = 0;
		this.file = file;
		this.current = tokens[0];

		var arr:Array<Expression> = [];

		while (!maybe(TEof)) {
			try {
				var e = parseExpression();
				switch (e.kind) {
					case EFunction(_, _, _, _) | EBlock(_) | EIf(_, _, _) | EWhile(_, _):
					default:
						switch (e.kind) {
							case EVar(_, _, _, _):
							default: checkSemicolon();
						}
				}
				arr.push(e);
			} catch (e:Exception) {
				throw new HscriptException('$file:${current.line}: characters ${current.start}-${current.end}: ${e.details()}', makeSpan(current));
			}
		}

		return {
			kind: EBlock(arr),
			span: {
				file: file,
				line: 0,
				start: 0,
				end: 0
			}
		};
	}

	private function parseExpression(minPrec:Int = 0):Expression {
		var e = parsePrimary();

		while (true) {
			var op = peekBinop();
			if (op == null)
				break;

			var prec = getPrecedence(op);
			if (prec < minPrec)
				break;

			advance(); 
			if (op.match(OpNullCoal))
				advance();

			var nextMinPrec = isRightAssociative(op) ? prec : prec + 1;
			var r = parseExpression(nextMinPrec);

			e = {kind: EBinop(op, e, r), span: mergeSpans(e.span, r.span)};
		}

		return e;
	}

	private function parsePrimary():Expression {
		var tok = advance();

		var e:Expression = switch (tok.kind) {
			case TPlusPlus:
				var operand = parsePrimary();
				makeExpr(EUnop(OpIncrement, operand, false), tok);

			case TMinus:
				var operand = parsePrimary();
				makeExpr(EUnop(OpNeg, operand, false), tok);

			case TNot:
				var operand = parsePrimary();
				makeExpr(EUnop(OpNot, operand, false), tok);

			case TBitNot:
				var operand = parsePrimary();
				makeExpr(EUnop(OpNegBits, operand, false), tok);

			case TLBrace:
				var objcs:Array<ObjectValue> = [];
				while (!maybe(TRBrace)) {
					var name:String = getIdent();
					expect(TColon);
					var value:Expression = parseExpression();
					objcs.push({name: name, value: value});
					if (!maybe(TComma)) {
						expect(TRBrace);
						break;
					}
				}
				makeExpr(EObjectDecl(objcs), tok);

			case TKeyword(WHILE):
				expect(TLParen);
				var cond = parseExpression();
				expect(TRParen);
				var body = parseBlock();
				makeExpr(EWhile(cond, body), tok);

			case TKeyword(DO):
				var b = parseBlock();
				expect(TKeyword(WHILE));
				expect(TLParen);
				var cond = parseExpression();
				expect(TRParen);
				makeExpr(EDoWhile(cond, b), tok);

			case TKeyword(VAR), TKeyword(FINAL):
				var start = makeSpan(tok);
				var isConst = tok.kind.equals(TKeyword(FINAL));
				var name = getIdent();
				var type:Types = null;
				var init:Expression = null;

				if (maybe(TColon))
					type = parseType();

				if (isConst) {
					try {
						expect(TAssign);
					} catch (_)
						throw 'Final variable $name must be initialized.';
					init = parseExpression();
				} else {
					if (maybe(TAssign))
						init = parseExpression();
				}

				checkSemicolon();

				return {
					kind: EVar(name, isConst, init, type),
					span: mergeSpans(start, init?.span ?? start)
				};

			case TKeyword(IF):
				expect(TLParen);
				var cond = parseExpression();
				expect(TRParen);
				var then = parseBlock();
				var elseExpr:Expression = null;
				if (current.kind.equals(TKeyword(ELSE))) {
					advance();
					elseExpr = parseBlock();
				}
				makeExpr(EIf(cond, then, elseExpr), tok);

			case TKeyword(SWITCH):
				expect(TLParen);
				var subject = parseExpression();
				expect(TRParen);
				expect(TLBrace);
				expect(TRBrace);
				makeExpr(ESwitch(subject, [], null), tok);

			case TKeyword(FUNCTION):
				var start = makeSpan(tok);
				var name:String = null;
				if (current.kind.match(TIdent(_)))
					name = getIdent();

				var args:Array<FunctionArgument> = [];
				var retType:Types = null;

				expect(TLParen);
				while (true) {
					if (maybe(TRParen))
						break;
					var opt = maybe(TQuestion);
					var argName = getIdent();
					var argType:Types = null;
					var def:Expression = null;
					if (maybe(TColon))
						argType = parseType();
					if (maybe(TAssign))
						def = parseExpression();
					args.push({
						name: argName,
						type: argType,
						def: def,
						optional: opt
					});
					if (!maybe(TComma)) {
						expect(TRParen);
						break;
					}
				}

				if (maybe(TColon))
					retType = parseType();

				var body = parseBlock();
				return {
					kind: EFunction(name, args, retType, body),
					span: mergeSpans(start, body.span)
				};

			case TKeyword(RETURN):
				var start = makeSpan(tok);
				var val:Expression = null;
				if (!current.kind.equals(TSemicolon) && !current.kind.equals(TRBrace))
					val = parseExpression();
				return {
					kind: EReturn(val),
					span: mergeSpans(start, val?.span ?? start)
				};

			case TKeyword(BREAK):
				makeExpr(EBreak, tok);

			case TKeyword(CONTINUE):
				makeExpr(EContinue, tok);

			case TKeyword(THROW):
				var val = parseExpression();
				makeExpr(EThrow(val), tok);

			case TKeyword(NEW):
				var start = makeSpan(tok);
				var typeName = parseType();
				expect(TLParen);
				var params:Array<Expression> = [];
				while (!current.kind.equals(TRParen)) {
					params.push(parseExpression());
					if (!maybe(TComma))
						break;
				}
				var end = makeSpan(expect(TRParen));
				{
					kind: ENew(typeName, params),
					span: mergeSpans(start, end)
				};

			case TInt(i): parsePostfix(makeExpr(EInt(i), tok));
			case TFloat(f): parsePostfix(makeExpr(EFloat(f), tok));
			case TString(s, _): parsePostfix(makeExpr(EString(s), tok));
			case TIdent(_): parsePostfix(makeExpr(EIdent(tok.kind.getParameters()[0]), tok));

			case TKeyword(TRUE): makeExpr(EBool(true), tok);
			case TKeyword(FALSE): makeExpr(EBool(false), tok);
			case TKeyword(NULL): makeExpr(ENull, tok);

			case TLBracket:
				var elements:Array<Expression> = [];
				var end:Span = null;
				while (true) {
					if (current.kind.equals(TRBracket)) {
						end = makeSpan(advance());
						break;
					}
					elements.push(parseExpression());
					if (!maybe(TComma)) {
						end = makeSpan(expect(TRBracket));
						break;
					}
				}
				parsePostfix({kind: EArrayDecl(elements), span: mergeSpans(makeSpan(tok), end)});

			case TLParen:
				var inner = parseExpression();
				expect(TRParen);
				parsePostfix(inner);

			case _:
				throw 'Unexpected token: ${Token.toLiteralString(tok.kind)}';
		};

		return e;
	}

	private function parsePostfix(e:Expression):Expression {
		while (true) {
			switch (current.kind) {
				case TPlusPlus:
					e = makeExpr(EUnop(OpIncrement, e, true), advance());

				case TMinusMinus:
					e = makeExpr(EUnop(OpDecrement, e, true), advance());

				case TLParen:
					advance();
					var args:Array<Expression> = [];
					while (!current.kind.equals(TRParen)) {
						args.push(parseExpression());
						if (!maybe(TComma))
							break;
					}
					var end = makeSpan(expect(TRParen));
					e = {kind: ECall(e, args), span: mergeSpans(e.span, end)};

				case TDot:
					advance();
					var field = getIdent();
					e = {kind: EField(e, field), span: mergeSpans(e.span, makeSpan(current))};

				case TLBracket:
					advance();
					var idx = parseExpression();
					var end = makeSpan(expect(TRBracket));
					e = {kind: EArray(e, idx), span: mergeSpans(e.span, end)};

				default:
					return e;
			}
		}
		return e;
	}

	private function parseBlock():Expression {
		if (current.kind.equals(TLBrace)) {
			var start:Span = makeSpan(advance());
			var end:Span = start;

			var b:Array<Expression> = [];
			while (true) {
				if (current.kind.equals(TRBrace)) {
					end = makeSpan(advance());
					break;
				}

				var e = parseExpression();
				switch (e.kind) {
					case EFunction(_, _, _, _) | EBlock(_) | EIf(_, _, _) | EWhile(_, _):
					default:
						switch (e.kind) {
							case EVar(_, _, _, _):
							default: checkSemicolon();
						}
				}

				b.push(e);
			}

			return {
				kind: EBlock(b),
				span: mergeSpans(start, end)
			}
		}

		var e = parseExpression();
		switch (e.kind) {
			case EFunction(_, _, _, _) | EBlock(_) | EIf(_, _, _) | EWhile(_, _):
			default:
				switch (e.kind) {
					case EVar(_, _, _, _):
					default: checkSemicolon();
				}
		}
		return e;
	}

	function makeExpr(kind:ExpressionKind, tok:Token):Expression {
		return {
			kind: kind,
			span: makeSpan(tok),
		};
	}

	private function isRightAssociative(op:Binop):Bool {
		return switch (op) {
			case OpAssign, OpAssignOp(_), OpArrow, OpNullCoal:
				true;
			default:
				false;
		};
	}

	private function getPrecedence(op:Binop):Int {
		return switch (op) {
			case OpAssignOp(_): 9;
			default:
				OP_PRECEDENCE.get(op) ?? -1;
		};
	}

	private function peekBinop():Null<Binop> {
		return switch (current.kind) {
			case TPlus: OpAdd;
			case TMinus: OpSub;
			case TStar: OpMult;
			case TSlash: OpDiv;
			case TPercent: OpMod;

			case TEqual: OpEq;
			case TNotEqual: OpNotEq;
			case TLess: OpLt;
			case TLessEqual: OpLte;
			case TGreater: OpGt;
			case TGreaterEqual: OpGte;

			case TBitAnd: OpAnd;
			case TBitOr: OpOr;
			case TBitXor: OpXor;

			case TAnd: OpBoolAnd;
			case TOr: OpBoolOr;

			case TShiftLeft: OpShl;
			case TShiftRight: OpShr;

			case TAssign: OpAssign;
			case TPlusAssign: OpAssignOp(OpAdd);
			case TMinusAssign: OpAssignOp(OpSub);
			case TStarAssign: OpAssignOp(OpMult);
			case TSlashAssign: OpAssignOp(OpDiv);
			case TPercentAssign: OpAssignOp(OpMod);
			case TAndAssign: OpAssignOp(OpAnd);
			case TOrAssign: OpAssignOp(OpOr);
			case TXorAssign: OpAssignOp(OpXor);

			case TInterval: OpInterval;

			case TArrow: OpArrow;
			case TQuestion:
				if (peek(1).kind.equals(TQuestion)) OpNullCoal else null;

			case TKeyword(IN): OpIn;

			default: null;
		};
	}

	function parseType():Types {
		if (maybe(TLBrace)) {
			var types:Array<AnonymousValue> = [];
			while (!maybe(TRBrace)) {
				var name:String = getIdent();
				expect(TColon);
				var type:Types = parseType();
				types.push({
					name: name,
					type: type
				});

				if (!maybe(TComma)) {
					expect(TRBrace);
					break;
				}
			}

			return TAnonymous(types);
		}
		var name:String = getIdent();
		var generic:Array<Types> = [];

		if (maybe(TLess)) {
			while (true) {
				generic.push(parseType());
				if (!maybe(TComma)) {
					expect(TGreater);
					break;
				}
			}
		}

		return TSimple(name, generic);
	}

	function getIdent():String {
		return switch (current.kind) {
			case TIdent(id):
				advance();
				id;
			default:
				throw 'Expected identifier, got ' + Token.toLiteralString(current.kind);
		};
	}

	function checkSemicolon() {
		if (!NeoHscript.STRICT_SEMICOLONS) {
			maybe(TSemicolon);
			return;
		}

		if (!maybe(TSemicolon))
			throw "Missing ;";
	}

	function getAssignOp():Binop {
		return switch (current.kind) {
			case TAssign: OpAssign;
			case TPlusAssign: OpAssignOp(OpAdd);
			case TMinusAssign: OpAssignOp(OpSub);
			case TStarAssign: OpAssignOp(OpMult);
			case TSlashAssign: OpAssignOp(OpDiv);
			case TPercentAssign: OpAssignOp(OpMod);
			case TAndAssign: OpAssignOp(OpAnd);
			case TOrAssign: OpAssignOp(OpOr);
			case TXorAssign: OpAssignOp(OpXor);
			default: OpAssign;
		};
	}

	function makeSpan(token:Token):Span {
		return {
			file: file,
			line: token.line,
			start: token.start,
			end: token.end
		};
	}

	function mergeSpans(s1:Span, s2:Span):Span {
		return {
			file: file,
			line: s1.line,
			start: s1.start,
			end: s2.end
		};
	}

	function peek(offset:Int = 0):Token {
		var idx:Int = pos + offset;
		return idx < tokens.length ? tokens[idx] : current;
	}

	function advance():Token {
		var prev:Token = current;
		if (pos < tokens.length - 1) {
			current = tokens[++pos];
		}
		return prev;
	}

	function maybe(t:TokenKind):Bool {
		if (current.kind.equals(t)) {
			advance();
			return true;
		}
		return false;
	}

	function match(kind:TokenKind):Bool {
		return Type.enumEq(current.kind, kind);
	}

	function expect(kind:TokenKind):Token {
		if (!match(kind)) {
			throw 'Expected ${Token.toLiteralString(kind)}, got ${Token.toLiteralString(current.kind)}';
		}
		return advance();
	}
}
