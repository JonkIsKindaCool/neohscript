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

	private function parseExpression():Expression {
		var tok = advance();

		var e:Expression = switch (tok.kind) {
			case TPlusPlus:
				makeExpr(EUnop(OpIncrement, parseExpression(), false), tok);
			case TMinus:
				makeExpr(EUnop(OpNeg, parseExpression(), false), tok);
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
				return makeExpr(EObjectDecl(objcs), tok);
			case TKeyword(WHILE):
				expect(TLParen);
				var cond:Expression = parseExpression();
				expect(TRParen);

				var body:Expression = parseBlock();
				makeExpr(EWhile(cond, body), tok);
			case TKeyword(DO):
				var b:Expression = parseBlock();
				expect(TKeyword(WHILE));
				null;
			case TKeyword(VAR), TKeyword(FINAL):
				var start:Span = makeSpan(tok);
				var isConst:Bool = current.kind.equals(TKeyword(FINAL));

				var name:String = getIdent();
				var type:Types = null;
				var e:Expression = null;
				if (maybe(TColon)) {
					type = parseType();
				}

				if (isConst) {
					try {
						expect(TAssign);
					} catch (e) {
						throw 'Final variable $name must be initialized.';
					}
					e = parseExpression();
				} else {
					if (maybe(TAssign))
						e = parseExpression();
				}

				checkSemicolon();

				return {
					kind: EVar(name, isConst, e, type),
					span: mergeSpans(start, e?.span ?? start)
				}
			case TKeyword(IF):
				expect(TLParen);
				var cond:Expression = parseExpression();
				expect(TRParen);

				var b:Expression = parseBlock();
				var e:Expression = null;

				switch (current.kind) {
					case TKeyword(ELSE):
						advance();
						e = parseBlock();
					case _:
				}

				return makeExpr(EIf(cond, b, e), tok);
			case TKeyword(FUNCTION):
				var start:Span = makeSpan(tok);

				var name:String = null;

				if (current.kind.match(TIdent(_)))
					name = getIdent();

				var args:Array<FunctionArgument> = [];
				var type:Types = null;

				expect(TLParen);
				while (true) {
					if (maybe(TRParen))
						break;

					var opt:Bool = maybe(TQuestion);
					var name:String = getIdent();
					var type:Types = null;
					var def:Expression = null;

					if (maybe(TColon)) {
						type = parseType();
					}

					if (maybe(TAssign))
						def = parseExpression();

					args.push({
						name: name,
						type: type,
						def: def,
						optional: opt
					});

					if (!maybe(TComma)) {
						expect(TRParen);
						break;
					}
				}

				if (maybe(TColon)) {
					type = parseType();
				}

				var e:Expression = parseBlock();

				return {
					kind: EFunction(name, args, type, e),
					span: mergeSpans(start, e.span),
				}
			case TKeyword(RETURN):
				var start:Span = makeSpan(tok);
				var e:Expression = null;
				if (!current.kind.equals(TSemicolon))
					e = parseExpression();

				return {
					kind: EReturn(e),
					span: mergeSpans(start, e?.span ?? start)
				}
			case TInt(i):
				parsePostFix(makeExpr(EInt(i), tok));

			case TFloat(f):
				parsePostFix(makeExpr(EFloat(f), tok));

			case TString(s, singleQuote):
				parsePostFix(parsePostFix(makeExpr(EString(s), tok)));

			case TIdent(id):
				parsePostFix(makeExpr(EIdent(id), tok));

			case TKeyword(TRUE):
				makeExpr(EBool(true), tok);

			case TKeyword(FALSE):
				makeExpr(EBool(false), tok);

			case TKeyword(NULL):
				makeExpr(ENull, tok);

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
				parsePostFix({
					kind: EArrayDecl(elements),
					span: mergeSpans(makeSpan(tok), end)
				});

			case TLParen:
				var e = parseExpression();
				expect(TRParen);
				parsePostFix(e);

			case _:
				throw 'Unexpected token in expression: ${Token.toLiteralString(tok.kind)}';
		};

		return e;
	}

	private function parsePostFix(e:Expression):Expression {
		while (true) {
			switch (current.kind) {
				case TPlusPlus:
					e = makeExpr(EUnop(OpIncrement, e, true), advance());
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
					var idx:Expression = parseExpression();
					var end = makeSpan(expect(TRBracket));
					e = {kind: EArray(e, idx), span: mergeSpans(e.span, end)};

				default:
					var op = peekBinop();
					if (op != null) {
						advance();
						if (op.match(OpNullCoal))
							advance();
						return makeBinop(op, e, parseExpression());
					}
					return e;
			}
		}
		return e;
	}

	private function makeBinop(op:Binop, e1:Expression, e2:Expression):Expression {
		switch (e2.kind) {
			case EBinop(op2, e2l, e3):
				var delta = getPrecedence(op) - getPrecedence(op2);
				if (delta < 0 || (delta == 0 && !op.match(OpAssignOp(_))))
					return {kind: EBinop(op2, makeBinop(op, e1, e2l), e3), span: mergeSpans(e2l.span, e3.span)};
				else
					return {kind: EBinop(op, e1, e2), span: mergeSpans(e1.span, e2.span)};
			default:
				return {kind: EBinop(op, e1, e2), span: mergeSpans(e1.span, e2.span)};
		}
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
		if (!NeoHscript.STRICT_SEMICOLONS)
			return;

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
