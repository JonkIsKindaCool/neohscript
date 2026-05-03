import hscript.bytecode.runtime.Interpreter;
import hscript.bytecode.compiler.Compiler;
import hscript.Interp;
import hscript.lexer.Lexer;
import hscript.ast.Parser;
import haxe.DynamicAccess;
import haxe.Resource;
import hscript.NeoHscript;

function main() {
	NeoHscript.STATIC_TYPING = false;
	NeoHscript.STRICT_SEMICOLONS = false;

	var name:String = "Test.hx";
	var src = Resource.getString("scripts/" + name);

	var program = new Compiler().compile(new Parser().parse(Lexer.tokenify(src), name), name);
	var interpreter:Interpreter = new Interpreter();

	var t1:Float = Sys.cpuTime() * 1000;

	var result:Dynamic = null;

	for (i in 0...1000)
		result = interpreter.execute(program);

	var t2:Float = Sys.cpuTime() * 1000;
	Sys.println('NEOHSCRIPT Execution: ${t2 - t1}ms');
	Sys.println('NEOHSCRIPT Restul: $result');

	var ast = new hscript.Parser(name).parseString(src);
	var i = new Interp(name);

	t1 = Sys.cpuTime() * 1000;

	for (_ in 0...1000)
		result = i.execute(ast);

	t2 = Sys.cpuTime() * 1000;

	Sys.println('Rewrite Execution: ${t2 - t1}ms');
	Sys.println('Rewrite Restul: $result');
}
