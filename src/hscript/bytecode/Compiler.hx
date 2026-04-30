package hscript.bytecode;

import hscript.data.Types;
import hscript.errors.HscriptException;
import hscript.ast.Span;
import haxe.Exception;
import hscript.ast.expressions.Expression;
import hscript.ast.expressions.ExpressionKind;
import hscript.bytecode.allocators.RegisterAllocator;

class Compiler {
	private var constantPool:Array<Dynamic> = [];
	private var instructions:Array<Instruction> = [];

	private var name:String;

	private var registerAllocator:RegisterAllocator;

	private var currentExpr:Expression;

	public function new() {
		registerAllocator = new RegisterAllocator();
	}

	public function compile(ast:Expression, ?name:String = "<unnamed>"):Program {
		this.name = name;
		constantPool = [];
		instructions = [];

		compileExpr(ast);

		return {instructions: instructions, constantPool: constantPool, filename: name};
	}

	private inline function pushScope() {
		registerAllocator.pushScope();
	}

	private inline function popScope() {
		registerAllocator.popScope();
	}

	private function compileExpr(e:Expression):Int {
		currentExpr = e;
		try {
			switch (e.kind) {
				case EBlock(arr):
					var last:Int = -1;
					for (a in arr)
						last = compileExpr(a);
					return last;

				case EArrayDecl(e):
					var regs:Array<Int> = [];
					for (elem in e)
						regs.push(compileExpr(elem));

					add_header_instruction(ARRAY);
					add_instruction(e.length);
					for (r in regs)
						add_instruction(r);

					for (r in regs)
						registerAllocator.free(r);

					var reg:Int = registerAllocator.allocateRegister();
					add_instruction(reg);
					return reg;

				case EObjectDecl(fields):
					var regs:Array<Int> = [];
					for (elem in fields)
						regs.push(compileExpr(elem.value));

					add_header_instruction(OBJECT);
					add_instruction(fields.length);

					for (i => elem in fields) {
						add_instruction(getConstant(elem.name));
						add_instruction(regs[i]);
					}

					var reg:Int = registerAllocator.allocateRegister();
					add_instruction(reg);
					return reg;

				case EArray(e, index):
					var src:Int = compileExpr(e);
					var target:Int = compileExpr(index);
					registerAllocator.free(src);
					registerAllocator.free(target);
					var reg:Int = registerAllocator.allocateRegister();

					add_header_instruction(INDEX);
					add_instruction(src);
					add_instruction(target);
					add_instruction(reg);

					return reg;

				case EField(p, f):
					var r:Int = compileExpr(p);
					var reg:Int = registerAllocator.allocateRegister();
					add_header_instruction(FIELD);
					add_instruction(r);
					add_instruction(reg);
					add_instruction(getConstant(f));

					return reg;

				case ECall(p, args):
					var argRegs:Array<Int> = [];
					for (a in args)
						argRegs.push(compileExpr(a));

					var target:Int = compileExpr(p);

					var reg:Int = registerAllocator.allocateRegister();

					add_header_instruction(p.kind.equals(EIdent("trace")) ? TRACE : CALL);
					add_instruction(target);
					add_instruction(reg);
					add_instruction(args.length);
					for (r in argRegs)
						add_instruction(r);

					registerAllocator.free(target);
					for (r in argRegs)
						registerAllocator.free(r);

					return reg;

				case EBool(b):
					var reg:Int = registerAllocator.allocateRegister();
					add_header_instruction(b ? TRUE : FALSE);
					add_instruction(reg);
					return reg;

				case EFunction(name, args, ret, body):
					if (name != null) {
						add_header_instruction(FUNCTION);
						add_instruction(getConstant(name));
					} else {
						add_header_instruction(ANONYMOUS_FUNCTION);
					}

					pushScope();

					add_instruction(args.length);
					for (arg in args) {
						add_instruction(getConstant(arg.name));
						add_instruction(arg.type != null ? 1 : 0);
						if (ret != null)
							compileType(arg.type);
					}

					add_instruction(ret != null ? 1 : 0);
					if (ret != null)
						compileType(ret);

					var len_loc:Int = instructions.length;
					add_instruction(0);

					compileExpr(body);

					instructions[len_loc] = instructions.length - (len_loc + 1);

					popScope();

					var reg:Int = registerAllocator.allocateRegister();
					add_instruction(reg);

					return reg;

				case ENull:
					var reg:Int = registerAllocator.allocateRegister();
					add_header_instruction(NULL);
					add_instruction(reg);
					return reg;

				case EInt(i):
					var reg = registerAllocator.allocateRegister();
					add_header_instruction(LOAD_CONSTANT);
					add_instruction(reg);
					add_instruction(getConstant(i));
					return reg;

				case EFloat(f):
					var reg = registerAllocator.allocateRegister();
					add_header_instruction(LOAD_CONSTANT);
					add_instruction(reg);
					add_instruction(getConstant(f));
					return reg;

				case EString(s):
					var reg = registerAllocator.allocateRegister();
					add_header_instruction(LOAD_CONSTANT);
					add_instruction(reg);
					add_instruction(getConstant(s));
					return reg;

				case EBinop(o, l, r):
					if (o == OpAssign) {
						var valReg = compileExpr(r);
						switch (l.kind) {
							case EIdent(n):
								add_header_instruction(STORE_LOCAL);
								add_instruction(valReg);
								add_instruction(getConstant(n));
							case _:
								throw "Invalid assignment target";
						}
						registerAllocator.free(valReg);
						return -1;
					}

					switch (o) {
						case OpAssignOp(inner):
							return compileExpr({
								kind: EBinop(OpAssign, l, {kind: EBinop(inner, l, r), span: r.span}),
								span: e.span
							});
						case _:
					}

					var regL = compileExpr(l);
					var regR = compileExpr(r);
					var regT = registerAllocator.allocateRegister();

					switch (o) {
						case OpAdd: add_header_instruction(OP_ADD);
						case OpSub: add_header_instruction(OP_SUB);
						case OpMult: add_header_instruction(OP_MULT);
						case OpDiv: add_header_instruction(OP_DIV);
						case OpMod: add_header_instruction(OP_MOD);
						case OpEq: add_header_instruction(OP_EQUAL);
						case OpNotEq: add_header_instruction(OP_NOT_EQUAL);
						case OpGt: add_header_instruction(OP_GT);
						case OpGte: add_header_instruction(OP_GTE);
						case OpLt: add_header_instruction(OP_LT);
						case OpLte: add_header_instruction(OP_LTE);
						case OpBoolAnd: add_header_instruction(OP_BOOL_AND);
						case OpBoolOr: add_header_instruction(OP_BOOL_OR);
						case OpAnd: add_header_instruction(OP_AND);
						case OpOr: add_header_instruction(OP_OR);
						case OpXor: add_header_instruction(OP_XOR);
						case OpShl: add_header_instruction(OP_SHL);
						case OpShr: add_header_instruction(OP_SHR);
						case OpUShr: add_header_instruction(OP_USHR);
						case OpInterval: add_header_instruction(OP_INTERVAL);
						case _: throw 'Unsupported binary operator: $o';
					}

					add_instruction(regL);
					add_instruction(regR);
					add_instruction(regT);
					registerAllocator.free(regL);
					registerAllocator.free(regR);
					return regT;

				case EUnop(o, p, post):
					var src = compileExpr(p);

					var dst = registerAllocator.allocateRegister();
					switch (o) {
						case OpNeg:
							add_header_instruction(OP_NEG);
							add_instruction(src);
							add_instruction(dst);
						case OpNot:
							add_header_instruction(OP_NOT);
							add_instruction(src);
							add_instruction(dst);
						case OpIncrement | OpDecrement:
							var one:Int = registerAllocator.allocateRegister();
							add_header_instruction(LOAD_CONSTANT);
							add_instruction(one);
							add_instruction(getConstant(1));

							if (!post) {
								add_header_instruction(o == OpIncrement ? OP_ADD : OP_SUB);
								add_instruction(src);
								add_instruction(one);
								add_instruction(dst);

								switch (p.kind) {
									case EIdent(n):
										add_header_instruction(STORE_LOCAL);
										add_instruction(dst);
										add_instruction(getConstant(n));
									case _:
								}
							} else {
								var newVal:Int = registerAllocator.allocateRegister();

								add_header_instruction(MOVE);
								add_instruction(src);
								add_instruction(dst);

								add_header_instruction(o == OpIncrement ? OP_ADD : OP_SUB);
								add_instruction(src);
								add_instruction(one);
								add_instruction(newVal);

								switch (p.kind) {
									case EIdent(n):
										add_header_instruction(STORE_LOCAL);
										add_instruction(newVal);
										add_instruction(getConstant(n));
									case _:
								}

								registerAllocator.free(newVal);
							}

							registerAllocator.free(one);
						case _: throw 'Unsupported unary operator: $o';
					}
					registerAllocator.free(src);
					return dst;

				case EIdent(i):
					var eReg:Int = registerAllocator.allocateRegister();
					add_header_instruction(LOAD_LOCAL);
					add_instruction(eReg);
					add_instruction(getConstant(i));
					return eReg;

				case EVar(n, f, e, t):
					var eReg:Int = -1;
					if (e != null)
						eReg = compileExpr(e);

					add_header_instruction(VAR_DECLARATION);
					add_instruction(getConstant(n));
					add_instruction(f ? 1 : 0);
					add_instruction(t != null ? 1 : 0);
					if (t != null)
						compileType(t);
					add_instruction(eReg);

					if (eReg != -1)
						registerAllocator.free(eReg);
					return -1;

				case EReturn(e):
					var reg:Int = -1;
					if (e != null)
						reg = compileExpr(e);
					add_header_instruction(RETURN);
					add_instruction(reg);
					if (reg != -1)
						registerAllocator.free(reg);
					return -1;

				case EIf(cond, then, elseExpr):
					var condReg:Int = compileExpr(cond);

					add_header_instruction(JUMP_IF_FALSE);
					add_instruction(condReg);

					var patchFalse:Int = instructions.length;
					add_instruction(0);
					registerAllocator.free(condReg);

					compileExpr(then);

					if (elseExpr != null) {
						add_header_instruction(JUMP);
						var patchEnd = instructions.length;
						add_instruction(0);

						instructions[patchFalse] = instructions.length - (patchFalse + 1);
						compileExpr(elseExpr);

						instructions[patchEnd] = instructions.length - (patchEnd + 1);
					} else {
						instructions[patchFalse] = instructions.length - (patchFalse + 1);
					}
					return -1;

				case EWhile(cond, body):
					var loopStart:Int = instructions.length;
					var condReg:Int = compileExpr(cond);

					add_header_instruction(JUMP_IF_FALSE);
					add_instruction(condReg);

					var patchExit:Int = instructions.length;

					add_instruction(0);
					registerAllocator.free(condReg);

					compileExpr(body);

					add_header_instruction(JUMP_BACK);
					add_instruction(instructions.length - loopStart + 1);

					instructions[patchExit] = instructions.length - (patchExit + 1);
					return -1;

				case EThrow(ex):
					var reg:Int = compileExpr(ex);
					add_header_instruction(THROW);
					add_instruction(reg);
					registerAllocator.free(reg);
					return -1;

				case _:
					return -1;
			}
		} catch (m:Exception) {
			#if debug
			throw new HscriptException('$name:${e.span.line}: characters ${e.span.start}-${e.span.end}: ${m.details()}', e.span);
			#else
			throw new HscriptException('$name:${e.span.line}: characters ${e.span.start}-${e.span.end}: ${m.message}', e.span);
			#end
		}
		return -1;
	}

	private inline function add_header_instruction(i:Instruction, ?pos:Expression) {
		pos ??= currentExpr;

		add_instruction(i);
		add_instruction(pos.span.line);
		add_instruction(pos.span.start);
		add_instruction(pos.span.end);
	}

	private inline function add_instruction(i:Instruction) {
		instructions.push(i);
	}

	private inline function compileType(t:Types) {
		switch (t) {
			case TSimple(name, generics):
				add_instruction(0);
				add_instruction(getConstant(name));
				add_instruction(generics.length);
				for (t in generics)
					compileType(t);
			case TAnonymous(v):
				add_instruction(1);
				add_instruction(v.length);
				for (value in v) {
					add_instruction(getConstant(value.name));
					compileType(value.type);
				}
			case TFunction(variables, ret):
				add_instruction(0);
		}
	}

	private function getConstant(v:Dynamic):Int {
		var idx:Int = constantPool.indexOf(v);
		if (idx == -1) {
			idx = constantPool.length;
			constantPool.push(v);
		}
		return idx;
	}
}
