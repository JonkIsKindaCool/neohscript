package hscript;

import hscript.bytecode.runtime.Interpreter;
import hscript.bytecode.compiler.Compiler;
import haxe.Log;
import haxe.PosInfos;
import hscript.ast.Span;
import haxe.extern.EitherType;
import hscript.bytecode.Program;
import hscript.lexer.Lexer;
import hscript.ast.expressions.Expression;
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

	public static var cacheVMS:Bool = true;

	private static var _cachedVMS:Map<String, Interpreter> = new Map();

	private static function _resolveScript(path:String):Interpreter {
		if (cacheVMS) {
			if (_cachedVMS.exists(path))
				return _cachedVMS.get(path);
		}

		var module:Expression = _resolveModule(path);

		if (module == null)
			return null;

		var program:Program = new Compiler().compile(module, path);

		return null;
	}

	private static function _resolveModule(path:String):Expression {
		return null;
	}

	private var content:String;

	private var parser:Parser;
	private var compiler:Compiler;
	private var interp:Interpreter;

	private var _stackedVariables:Map<String, Dynamic>;

	public function new() {
		_stackedVariables = new Map();
		parser = new Parser();
		compiler = new Compiler();
		interp = new Interpreter();
	}

	public function setGlobal(name:String, v:Dynamic) {
	}

	public function getGlobal(name:String):Dynamic {
		return null;
	}

	public function execute(script:String, ?file:String):Dynamic {
		this.content = script;

		var ast:Expression = parser.parse(Lexer.tokenify(content), file);
		var bytecode:Program = compiler.compile(ast, file);

		return null;
	}
}
