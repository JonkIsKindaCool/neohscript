package hscript;

import haxe.Log;
import haxe.PosInfos;
import hscript.ast.Span;
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

	public static var DEFAULT_IMPORTS:Map<String, Dynamic> = [
		"trace" => function(a:Dynamic, pos:Span) {
			var pos:PosInfos = {
				fileName: pos.file,
				lineNumber: pos.line,
				className: "<unnamed>",
				methodName: "<unnamed>"
			};
			Log.trace(a, pos);
		},
		'Reflect' => Reflect,
		'Std' => Std,
		'Math' => Math,
		#if sys 'Sys' => Sys, #end
		'Type' => Type,
		'StringTools' => StringTools,
		'Date' => Date,
		'DateTools' => DateTools,
		'Xml' => Xml,
		'Int' => Int,
		'String' => String,
		'StringBuf' => StringBuf,
		'Float' => Float,
		'Bool' => Bool,
		'Array' => Array,
		'Lambda' => Lambda,
		'EReg' => EReg
	];

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
		vm.define(name, v);
	}

	public function getGlobal(name:String):Dynamic {
		return vm.get(name);
	}

	public function execute(script:String, ?file:String):Dynamic {
		this.content = script;

		var ast:Expression = parser.parse(Lexer.tokenify(content), file);
		var bytecode:Program = compiler.compile(ast, file);

		return vm.execute(bytecode);
	}
}
