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
		constantPool = [];
		instructions = [];

		registerAllocator = new RegisterAllocator();
		variableAllocator = new VariableAllocator();

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
				trace(n, f, e, t?.name);
		}
	}

	private function compileExpr(e:Expression) {
		try {
			switch (e.kind) {
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
