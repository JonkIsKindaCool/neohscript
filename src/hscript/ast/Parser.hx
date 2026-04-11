package hscript.ast;

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

	public function new(tokens:Array<Token>, file:String = "main") {
		this.tokens = tokens;
		this.file = file;
		this.current = tokens[0];
	}

	public function parse():Array<Declaration> {
		var arr:Array<Declaration> = [];

		while (!maybe(TEof)) {
			arr.push(parseDecl());
		}

		return arr;
	}

	function parseDecl():Declaration {
		var expr:Expression = parseStmt();
		return {kind: DExpr(expr), span: makeComplexSpan(expr.span, expr.span)};
	}

	function parseStmt():Expression {
		var acess:Array<Access> = [];
		switch (current.kind) {
			case TLBrace:
				var start:Token = advance();
				var body:Array<Expression> = [];
				while (!maybe(TRBrace)) {
					body.push(parseStmt());
				}
				return {
					kind: EBlock(body),
					span: makeSpan(start),
					access: []
				}
			case TKeyword(RETURN):
				var start = advance();
				var expr:Expression = null;

				if (!current.kind.equals(TSemicolon)) {
					expr = parseExpr();
				}
				checkSemicolon();

				return {
					kind: EReturn(expr),
					span: mergeSpans(makeSpan(start), expr.span),
					access: []
				}
			case TKeyword(FUNCTION):
				var start:Token = advance();
				var name:String = null;
				var args:Array<FunctionArgument> = new Array();
				var ret:ASTType = null;
				var expr:Expression = null;

				if (current.kind.match(TIdent(_)))
					name = getIdent();

				expect(TLParen);
				while (true) {
					if (maybe(TRParen))
						break;

					var optional:Bool = maybe(TQuestion);

					var name:String = getIdent();
					var type:ASTType = null;
					var def:Expression = null;

					if (maybe(TColon))
						type = parseType();

					if (maybe(TAssign))
						def = parseExpr();

					args.push({
						name: name,
						type: type,
						def: def,
						optional: optional
					});

					if (!maybe(TComma)) {
						expect(TRParen);
						break;
					}
				}

				if (maybe(TColon))
					ret = parseType();

				expr = parseStmt();

				return {
					kind: EFunction(name, args, ret, expr),
					span: makeSpan(start),
					access: acess
				}
			case _:
		}

		var expr:Expression = parseExpr();
		checkSemicolon();
		return expr;
	}

	function parseExpr():Expression {
		return parseAssignment();
	}

	function parseAssignment():Expression {
		var expr:Expression = parseOr();

		if (match(TAssign) || match(TPlusAssign) || match(TMinusAssign) || match(TStarAssign) || match(TSlashAssign) || match(TPercentAssign)
			|| match(TAndAssign) || match(TOrAssign) || match(TXorAssign)) {
			var op:Binop = getAssignOp();
			advance();
			var right:Expression = parseAssignment();
			return {
				kind: EBinop(op, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseOr():Expression {
		var expr:Expression = parseAnd();

		if (match(TOr)) {
			advance();
			var right:Expression = parseAnd();
			expr = {
				kind: EBinop(OpBoolOr, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseAnd():Expression {
		var expr:Expression = parseBitOr();

		if (match(TAnd)) {
			advance();
			var right:Expression = parseBitOr();
			expr = {
				kind: EBinop(OpBoolAnd, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseBitOr():Expression {
		var expr:Expression = parseBitXor();

		if (match(TBitOr)) {
			advance();
			var right:Expression = parseBitXor();
			expr = {
				kind: EBinop(OpOr, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseBitXor():Expression {
		var expr:Expression = parseBitAnd();

		if (match(TBitXor)) {
			advance();
			var right:Expression = parseBitAnd();
			expr = {
				kind: EBinop(OpXor, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseBitAnd():Expression {
		var expr:Expression = parseEquality();

		if (match(TBitAnd)) {
			advance();
			var right:Expression = parseEquality();
			expr = {
				kind: EBinop(OpAnd, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseEquality():Expression {
		var expr:Expression = parseComparison();

		if (match(TEqual) || match(TNotEqual)) {
			var op:Binop = match(TEqual) ? OpEq : OpNotEq;
			advance();
			var right:Expression = parseComparison();
			expr = {
				kind: EBinop(op, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseComparison():Expression {
		var expr:Expression = parseShift();

		if (match(TLess) || match(TLessEqual) || match(TGreater) || match(TGreaterEqual)) {
			var op:Binop = switch (current.kind) {
				case TLess: OpLt;
				case TLessEqual: OpLte;
				case TGreater: OpGt;
				case TGreaterEqual: OpGte;
				default: OpLt;
			};
			advance();
			var right:Expression = parseShift();
			expr = {
				kind: EBinop(op, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseShift():Expression {
		var expr:Expression = parseAdditive();

		if (match(TShiftLeft) || match(TShiftRight)) {
			var op:Binop = match(TShiftLeft) ? OpShl : OpShr;
			advance();
			var right:Expression = parseAdditive();
			expr = {
				kind: EBinop(op, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseAdditive():Expression {
		var expr:Expression = parseMultiplicative();

		if (match(TPlus) || match(TMinus)) {
			var op:Binop = match(TPlus) ? OpAdd : OpSub;
			advance();
			var right:Expression = parseMultiplicative();
			expr = {
				kind: EBinop(op, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseMultiplicative():Expression {
		var expr:Expression = parseUnary();

		if (match(TStar) || match(TSlash) || match(TPercent)) {
			var op:Binop = switch (current.kind) {
				case TStar: OpMult;
				case TSlash: OpDiv;
				case TPercent: OpMod;
				default: OpMult;
			};
			advance();
			var right:Expression = parseUnary();
			expr = {
				kind: EBinop(op, expr, right),
				span: mergeSpans(expr.span, right.span),
				access: []
			};
		}

		return expr;
	}

	function parseUnary():Expression {
		var start:Token = current;

		if (match(TNot) || match(TMinus) || match(TPlus) || match(TBitNot) || match(TPlusPlus) || match(TMinusMinus)) {
			var op:Unop = switch (current.kind) {
				case TNot: OpNot;
				case TMinus: OpNeg;
				case TBitNot: OpNegBits;
				case TPlusPlus: OpIncrement;
				case TMinusMinus: OpDecrement;
				default: OpNot;
			};
			advance();
			var expr:Expression = parseUnary();
			return {
				kind: EUnop(op, expr, false),
				span: mergeSpans(makeSpan(start), expr.span),
				access: []
			};
		}

		return parsePostfix();
	}

	function parsePostfix():Expression {
		var expr = parsePrimary();
		while (true) {
			if (match(TLParen)) {
				advance();
				var args = [];
				if (!match(TRParen)) {
					do {
						args.push(parseExpr());
					} while (maybe(TComma));
				}
				expect(TRParen);
				expr = {
					kind: ECall(expr, args),
					span: mergeSpans(expr.span, makeSpan(current)),
					access: []
				};
			} else if (match(TDot)) {
				advance();
				var f = getIdent();
				expr = {
					kind: EField(expr, f),
					span: mergeSpans(expr.span, makeSpan(current)),
					access: []
				};
			} else if (match(TLBracket)) {
				advance();
				var idx = parseExpr();
				expect(TRBracket);
				expr = {
					kind: EArray(expr, idx),
					span: mergeSpans(expr.span, makeSpan(current)),
					access: []
				};
			} else
				break;
		}
		return expr;
	}

	function parsePrimary():Expression {
		var start = current;

		return switch (current.kind) {
			case TInt(i):
				advance();
				{
					kind: EInt(i),
					span: makeSpan(start),
					access: []
				};
			case TFloat(f):
				advance();
				{
					kind: EFloat(f),
					span: makeSpan(start),
					access: []
				};
			case TString(s, _):
				advance();
				{
					kind: EString(s),
					span: makeSpan(start),
					access: []
				};
			case TIdent(id):
				advance();
				{
					kind: EIdent(id),
					span: makeSpan(start),
					access: []
				};

			case TKeyword(TRUE):
				advance();
				{
					kind: EBool(true),
					span: makeSpan(start),
					access: []
				};
			case TKeyword(FALSE):
				advance();
				{
					kind: EBool(false),
					span: makeSpan(start),
					access: []
				};
			case TKeyword(NULL):
				advance();
				{
					kind: ENull,
					span: makeSpan(start),
					access: []
				};

			case TKeyword(NEW):
				advance();
				var t = parseType();
				expect(TLParen);
				var params = [];
				if (!match(TRParen)) {
					do {
						params.push(parseExpr());
					} while (maybe(TComma));
				}
				expect(TRParen);
				{
					kind: ENew(t, params),
					span: makeSpan(start),
					access: []
				};

			case TLBracket:
				advance();
				var values = [];
				if (!match(TRBracket)) {
					do {
						values.push(parseExpr());
					} while (maybe(TComma));
				}
				expect(TRBracket);
				{
					kind: EArrayDecl(values),
					span: makeSpan(start),
					access: []
				};

			case TLParen:
				advance();
				var e = parseExpr();
				expect(TRParen);
				e;
			case _:
				throw 'Unexpected token: ${Token.toLiteralString(current.kind)}';
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
