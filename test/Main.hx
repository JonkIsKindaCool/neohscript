import nx.script.Bytecode.Value;
import nx.script.VM;
import nx.script.Tokenizer;
import hscript.bytecode.Program;
import hscript.Interp;
import hscript.lexer.Lexer;
import hscript.ast.Parser;
import haxe.DynamicAccess;
import haxe.Resource;
import hscript.NeoHscript;

function main() {
	var name:String = "Test.hx";
	var src = Resource.getString("scripts/" + name);

	var t1:Float = Sys.cpuTime() * 1000;

	var result:Dynamic = null;

	var t2:Float = Sys.cpuTime() * 1000;
	Sys.println('NEOHSCRIPT Execution (1000 runs): ${t2 - t1} seconds');
	Sys.println('NEOHSCRIPT Result: $result');

	Sys.println("");

	var ast = new hscript.Parser(name).parseString(src);
	var i = new Interp(name);

	t1 = Sys.cpuTime() * 1000;

	for (_ in 0...1000)
		result = i.execute(ast)();

	t2 = Sys.cpuTime() * 1000;

	Sys.println('Rewrite Execution (1000 runs): ${t2 - t1} seconds');
	Sys.println('Rewrite Result: $result');

	Sys.println("");

	var compiler = new nx.script.Compiler();
	var chunk = compiler.compile(new nx.script.Parser(new Tokenizer().init(src).tokenize()).parse());

	var interp:VM = new VM();
	interp.scriptName = name;
	interp.natives.set("Math", VNativeObject(Math));
	interp.natives.set("trace", VNativeFunction("trace", -1, function(args:Array<Value>):Value {
		var parts:Array<Dynamic> = [];
		for (arg in args) {
			parts.push(interp.valueToHaxe(arg));
		}

		// Get current instruction line info
		var lineInfo = "";
		if (interp.currentInstruction != null) {
			lineInfo = '${interp.scriptName}:${interp.currentInstruction.line}: ';
		}
		#if sys
		Sys.println(lineInfo + parts.join(" "));
		#else
		trace(lineInfo + parts.join(" "));
		#end

		return VNull;
	}));

	for (name in compiler.staticGlobalNames.keys())
		interp.staticNames.set(name, true);

	t1 = Sys.cpuTime() * 1000;

	for (_ in 0...1000) {
		interp.execute(chunk);
		result = interp.safeCall("main");
	}

	t2 = Sys.cpuTime() * 1000;

	Sys.println('NXScript Execution (1000 runs): ${t2 - t1} seconds');
	Sys.println('NXScript Result: $result');
}
