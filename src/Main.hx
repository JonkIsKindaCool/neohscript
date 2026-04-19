import hscript.bytecode.Unpacker;
import sys.io.File;
import hscript.bytecode.Packer;
import haxe.io.Bytes;
import hscript.Interp;
import hscript.vm.VM;
import hscript.bytecode.Compiler;
import hscript.ast.Parser;
import haxe.Resource;
import hscript.lexer.Lexer;
import hscript.lexer.Token;

@:access(hscript.Parser)
class Main {
	static function main() {
		try {
			var res:String = Resource.getString("Test.hx");
			var t1:Float = Sys.time();
			var tokens:Array<Token> = Lexer.tokenify(res);

			var parser:Parser = new Parser();
			var decls = parser.parse(tokens, "Test.hx");

			var t2:Float = Sys.time();

			Sys.println("NeoHSCRIPT Parsing Time: " + (t2 - t1) * 1000 + "ms");
			t1 = Sys.time();
			var parser:hscript.Parser = new hscript.Parser();
			var ast = parser.parseString(res);
			t2 = Sys.time();

			Sys.println("HSCRIPT-REWRITE Parsing Time: " + (t2 - t1) * 1000 + "ms");

			var instructions = new Compiler().compile(decls);
			trace(instructions.instructions);

			var vm:VM = new VM();
			t1 = Sys.time();
			var result = vm.execute(instructions);
			t2 = Sys.time();

			Sys.println("NeoHSCRIPT Execution Time: " + (t2 - t1) * 1000 + "ms");
			Sys.println("NeoHSCRIPT Result: " + result);

			var interp:Interp = new Interp();
			t1 = Sys.time();
			result = interp.execute(ast);
			t2 = Sys.time();

			Sys.println("HSCRIPT-REWRITE Execution Time: " + (t2 - t1) * 1000 + "ms");
			Sys.println("HSCRIPT-REWRITE Result: " + result);

			var bytes:Bytes = Packer.pack(instructions);
			File.saveBytes('test.nh', bytes);

			trace(Unpacker.unpack(bytes).instructions);
		} catch (e){
			Sys.println(e);
		}
	}
}
