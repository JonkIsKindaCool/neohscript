package hscript.bytecode;

import haxe.Exception;
import hscript.ast.expressions.Expression;
import hscript.bytecode.allocators.VariableAllocator;
import hscript.bytecode.allocators.RegisterAllocator;
import hscript.ast.declarations.Declaration;

class Compiler {
	private var constantPool:Array<Dynamic> = [];
	private var instructions:Array<Instruction> = [];

	private var name:String;
	private var ast:Array<Declaration>;

	private var registerAllocator:RegisterAllocator;
	private var variableAllocator:VariableAllocator;

	public function new() {}

	public function compile(ast:Array<Declaration>, ?name:String = "<unnamed>"):Program {
		this.name = name;
		constantPool = [];
		instructions = [];

		registerAllocator = new RegisterAllocator();
		variableAllocator = new VariableAllocator(this);

		for (decl in ast) {
			compileDecl(decl);
		}

		return {instructions: instructions, constantPool: constantPool};
	}

	private function compileDecl(d:Declaration) {
		switch (d.kind) {
			case DExpr(e):
				compileExpr(e);
			case DVar(n, f, e, t):
				if (d.access.contains(AInline)){
					variableAllocator.setInline(n, e, f, t);
					return;
				}
				
				var eReg:Int = -1;
				if (e != null){
					eReg = compileExpr(e);
				}

				add_instruction(TOP_LEVEL_VAR_DECLARATION);
				add_instruction(getConstant(n));
				add_instruction(variableAllocator.setVariable(n, f, t));
				add_instruction(eReg);

				registerAllocator.free(eReg);
		}
	}

	private function compileExpr(e:Expression):Int {
		try {
			switch (e.kind) {
				case ECall(p, args):
					return -1;
				case EBool(b):
					var reg:Int = registerAllocator.allocateRegister();
					add_instruction(b ? TRUE : FALSE);
					add_instruction(reg);

					return reg;
				case ENull:
					var reg:Int = registerAllocator.allocateRegister();
					add_instruction(NULL);
					add_instruction(reg);

					return reg;
				case EInt(i):
					var reg = registerAllocator.allocateRegister();
					add_instruction(LOAD_CONSTANT);
					add_instruction(reg);
					add_instruction(getConstant(i));
					return reg;

				case EFloat(i):
					var reg = registerAllocator.allocateRegister();
					add_instruction(LOAD_CONSTANT);
					add_instruction(reg);
					add_instruction(getConstant(i));
					return reg;

				case EString(i):
					var reg = registerAllocator.allocateRegister();
					add_instruction(LOAD_CONSTANT);
					add_instruction(reg);
					add_instruction(getConstant(i));
					return reg;

				case EBinop(o, l, r):
					var regL = compileExpr(l);
					var regR = compileExpr(r);
					var regT = registerAllocator.allocateRegister();
					switch (o) {
						case OpAdd: add_instruction(OP_ADD);
						case OpSub: add_instruction(OP_SUB);
						case OpMult: add_instruction(OP_MULT);
						case OpDiv: add_instruction(OP_DIV);

						case _:
					}
					add_instruction(regL);
					add_instruction(regR);
					add_instruction(regT);
					registerAllocator.free(regL);
					registerAllocator.free(regR);
					return regT;

				case EIdent(i):
					if (!variableAllocator.exists(i)){
						throw "Variable " +i +" doesn't exists.";
					}
					if (variableAllocator.isInline(i)){
						var reg:Int = compileExpr(variableAllocator.getInline(i));
						return reg;
					}
					var eReg:Int = registerAllocator.allocateRegister();
					add_instruction(LOAD_LOCAL);
					add_instruction(eReg);
					add_instruction(variableAllocator.getVariable(i));

					return eReg;

				case _:
					return -1;
			}
		} catch (m:Exception) {
			#if debug 
			throw '$name:${e.span.line}: characters ${e.span.start}-${e.span.end}: ${m.details()}';
			#else 
			throw '$name:${e.span.line}: characters ${e.span.start}-${e.span.end}: ${m.message}';
			#end
		}
	}

	private inline function add_instruction(i:Instruction) {
		instructions.push(i);
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
