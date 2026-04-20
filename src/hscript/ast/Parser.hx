package hscript.ast;

import haxe.Exception;
import haxe.ds.GenericStack;
import hscript.ast.declarations.Declaration;
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

	public function parse(tokens:Array<Token>, file:String = "<unnamed>"):Array<Declaration> {
		this.tokens = tokens;
		this.pos = 0;
		this.file = file;
		this.current = tokens[0];

		var arr:Array<Declaration> = [];

		while (!maybe(TEof)) {
			try {
				arr.push(parseDeclaration());
			} catch (e:Exception) {
				throw '$file:${current.line}: characters ${current.start}-${current.end}: ${e.details()}';
			}
		}

		return arr;
	}

	function parseDeclaration():Declaration {
		var realDeclaration:Bool = false;
		var access:Array<Access> = [];

		switch (current.kind) {
			case TKeyword(PUBLIC), TKeyword(PRIVATE), TKeyword(STATIC), TKeyword(INLINE):
				realDeclaration = true;
				while (true) {
					switch (current.kind) {
						case TKeyword(PUBLIC):
							advance();
							access.push(APublic);
						case TKeyword(PRIVATE):
							advance();
							access.push(APrivate);
						case TKeyword(INLINE):
							advance();
							access.push(AInline);
						case TKeyword(STATIC):
							advance();
							access.push(AStatic);
						case _:
							break;
					}
				}
			case TKeyword(VAR), TKeyword(FINAL), TKeyword(FUNCTION):
				realDeclaration = true;
			default:
		}

		if (realDeclaration) {
			switch (current.kind) {
				case TKeyword(VAR), TKeyword(FINAL):
					var start:Span = makeSpan(current);
					var isConst:Bool = current.kind.equals(TKeyword(FINAL));
					advance();

					var name:String = getIdent();
					var type:ASTType = null;
					var e:Expression = null;
					if (maybe(TColon)) {
						type = parseType();
					}

					if (isConst) {
						try {
							expect(TAssign);
						} catch (e) {
							throw 'Static final variable $name must be initialized.';
						}
						e = parseExpression();
					} else {
						if (maybe(TAssign))
							e = parseExpression();
					}

					checkSemicolon();

					return {
						kind: DVar(name, isConst, e, type),
						access: [],
						span: makeComplexSpan(start, e?.span ?? start)
					}
				case _:
					throw 'Expected Declaration, found anything else.';
			}
		}

		var decl:Expression = parseExpression();
		checkSemicolon();
		return {
			kind: DExpr(decl),
			span: makeComplexSpan(decl.span, decl.span),
			access: []
		}
	}

	public function parseExpression(minPrecedence:Int = 0):Expression {
		var left:Expression = parsePrimitive();

		while (true) {
			var op:Binop = peekBinop();
			if (op == null)
				break;

			var prec:Int = getPrecedence(op);
			if (prec < minPrecedence)
				break;

			advance();

			var nextMinPrec:Int = (isRightAssociative(op)) ? prec : prec + 1;

			var right:Expression = parseExpression(nextMinPrec);

			left = makeBinop(left, op, right);
		}

		return left;
	}

	function parseStatement(id:String, tok:Token):Expression {
		switch (id) {
			case _:
				return makeExpr(EIdent(id), tok);
		}
	}

	private function parsePrimitive():Expression {
		var tok = advance();

		return switch (tok.kind) {
			case TInt(i):
				makeExpr(EInt(i), tok);

			case TFloat(f):
				makeExpr(EFloat(f), tok);

			case TString(s, singleQuote):
				parsePostFix(makeExpr(EString(s), tok));

			case TIdent(id):
				parsePostFix(parseStatement(id, tok));

			case TKeyword(TRUE):
				makeExpr(EBool(true), tok);

			case TKeyword(FALSE):
				makeExpr(EBool(false), tok);

			case TKeyword(NULL):
				makeExpr(ENull, tok);

			case TLParen:
				var e = parseExpression();
				expect(TRParen);
				parsePostFix(e);

			case _:
				throw 'Unexpected token in expression: ${Token.toLiteralString(tok.kind)}';
		};
	}

	private function parsePostFix(e:Expression):Expression {
		switch (current.kind) {
			case TLParen:
				advance();
				var args:Array<Expression> = [];
				while (true) {
					if (current.kind.equals(TRParen)) {
						advance();
						break;
					}
					args.push(parseExpression());

					if (!maybe(TComma)) {
						expect(TRParen);
						break;
					}
				}

				return {
					span: e.span,
					kind: ECall(e, args)
				}
			default:
				return e;
		}
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

			case TArrow: OpArrow;
			case TQuestion:
				if (peek(1).kind.equals(TQuestion)) OpNullCoal else null;

			case TKeyword(IN): OpIn;

			default: null;
		};
	}

	private function makeBinop(left:Expression, op:Binop, right:Expression):Expression {
		var span:Span = mergeSpans(left.span, right.span);
		return {
			kind: EBinop(op, left, right),
			span: span,
		};
	}

	function parseType():ASTType {
		var name:String = getIdent();
		var generic:Array<ASTType> = [];

		if (maybe(TLess)) {
			while (true) {
				generic.push(parseType());
				if (!maybe(TComma)) {
					expect(TGreater);
					break;
				}
			}
		}

		return {
			name: name,
			generics: generic
		}
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

	function makeComplexSpan(s:Span, e:Span):ComplexSpan {
		return {
			file: file,
			start: s,
			end: e
		}
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
