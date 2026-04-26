package hscript;

import haxe.extern.EitherType;
import hscript.bytecode.Program;
import hscript.bytecode.Instruction;
import hscript.lexer.Lexer;
import hscript.ast.expressions.Expression;
import hscript.vm.VM;
import hscript.bytecode.Compiler;
import hscript.ast.Parser;

@:access(hscript.bytecode.Compiler)
@:access(hscript.vm.VM)
class NeoHscript {
	public static var STRICT_SEMICOLONS:Bool = true;
	public static var STATIC_TYPING:Bool = true;

	private var content:String;

	private var parser:Parser;
	private var compiler:Compiler;
	private var vm:VM;

	private var _stackedVariables:Map<String, Dynamic>;

	public function new() {
		_stackedVariables = new Map();
		parser = new Parser();
		compiler = new Compiler();
		vm = new VM();
	}

	public function setGlobal(name:String, v:Dynamic) {
		_stackedVariables.set(name, v);
	}

	public function getGlobal(name:String):Dynamic {
		return vm.getGlobal(name);
	}

	public function execute(script:String, ?file:String):Dynamic {
		this.content = script;

		var ast:Expression = parser.parse(Lexer.tokenify(content), file);
		for (name => variable in _stackedVariables){
			var id:Int = compiler.variableAllocator.setVariable(name, false);
			vm.variables[id] = {
				value: variable,
				type: "Dynamic"
			};
			vm.variablesTable[name] = id;
		}
		var bytecode:Program = compiler.compile(ast, file);

		return vm.execute(bytecode);
	}
}
