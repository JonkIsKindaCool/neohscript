package hscript.bytecode.compiler;

import hscript.errors.HscriptException;
import haxe.Exception;
import hscript.ast.expressions.Expression;
import hscript.ast.Span;

class Compiler {
	private var bytes:Array<Byte>;
	private var constants:Array<Dynamic>;
	private var positions:Array<Span>;

	private var file:String;

	public function new() {}

	public function compile(e:Expression, ?file:String = "<unnamed>"):Program {
		bytes = [];
		constants = [];
		positions = [];

		this.file = file;

		compileExpression(e);
		trace(e);

		return {
			bytes: bytes,
			constants: constants,
			positions: positions
		}
	}

	private function compileExpression(e:Expression) {
		positions.push(e.span);
		try {
			switch (e.kind) {
				case EBlock(arr):
					for (e in arr)
						compileExpression(e);
				case EInt(i):
					addByte(GET_CONSTANT);
					addByte(getConstant(i));
				case EFloat(f):
					addByte(GET_CONSTANT);
					addByte(getConstant(f));
				case EString(s):
					addByte(GET_CONSTANT);
					addByte(getConstant(s));
				case EIdent(i):
				case EBool(b):
				case ENull:
				case EBinop(o, l, r):
					switch (o) {
						case OpAdd: addByte(OP_ADD);
						case OpSub: addByte(OP_SUB);
						case OpMult: addByte(OP_MULT);
						case OpDiv: addByte(OP_DIV);
						case OpMod: addByte(OP_MOD);
						case OpEq: addByte(OP_EQUAL);
						case OpNotEq: addByte(OP_NOT_EQUAL);
						case OpGt: addByte(OP_GT);
						case OpGte: addByte(OP_GTE);
						case OpLt: addByte(OP_LT);
						case OpLte: addByte(OP_LTE);
						case OpBoolAnd: addByte(OP_BOOL_AND);
						case OpBoolOr: addByte(OP_BOOL_OR);
						case OpAnd: addByte(OP_AND);
						case OpOr: addByte(OP_OR);
						case OpXor: addByte(OP_XOR);
						case OpShl: addByte(OP_SHL);
						case OpShr: addByte(OP_SHR);
						case OpUShr: addByte(OP_USHR);
						case OpInterval: addByte(OP_INTERVAL);
						case _: throw 'Unsupported binary operator: $o';
					}
                    compileExpression(l);
                    compileExpression(r);
				case EUnop(o, p, post):
				case ECall(p, args):
				case EField(p, f):
				case EArray(e, index):
				case EArrayDecl(values):
				case EObjectDecl(fields):
				case EIf(cond, then, elseExpr):
				case ESwitch(subject, cases, defaultExpr):
				case ENew(t, params):
				case EFunction(name, args, ret, body):
				case EReturn(e):
				case EBreak:
				case EContinue:
				case EThrow(e):
				case ETry(e, catches):
				case EVar(n, f, e, t):
				case EWhile(c, b):
				case EDoWhile(c, b):
			}
		} catch (err:Exception) {
			throw new HscriptException(err.message, e.span);
		}
	}

	private function addByte(b:Byte) {
		bytes.push(b);
	}

	private function getConstant(c:Dynamic):Int {
		var idx:Int = constants.indexOf(c);

		if (idx == -1) {
			idx = constants.length;
			constants.push(c);
		}

		return idx;
	}
}
