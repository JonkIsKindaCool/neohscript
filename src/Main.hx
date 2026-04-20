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
            var code:String = Resource.getString("Test.hx");

            var parser = new Parser();
            var compiler = new Compiler();
            var vm = new VM();
            var interp = new Interp();
            interp.fileName = "Test.hx";

            var t1:Float = Sys.time();
            for (i in 0...1000) {
                var tokens:Array<Token> = Lexer.tokenify(code);
                var decls = parser.parse(tokens, "Test.hx");
            }
            var t2:Float = Sys.time();
            Sys.println("NeoHSCRIPT Parsing Time (1000 runs): " + ((t2 - t1)) + " seconds");

            t1 = Sys.time();
            for (i in 0...1000) {
                var standardParser:hscript.Parser = new hscript.Parser();
                var ast = standardParser.parseString(code);
            }
            t2 = Sys.time();
            Sys.println("HSCRIPT-REWRITE Parsing Time (1000 runs): " + ((t2 - t1)) + " seconds");

            var tokens:Array<Token> = Lexer.tokenify(code);
            var decls = parser.parse(tokens, "Test.hx");
            var instructions = compiler.compile(decls, "Test.hx");

            t1 = Sys.time();
            for (i in 0...1000) {
                var result = vm.execute(instructions);
            }
            t2 = Sys.time();
            Sys.println("NeoHSCRIPT Execution Time (1000 runs): " + ((t2 - t1)) + " seconds");

            var standardParser:hscript.Parser = new hscript.Parser();
            var ast = standardParser.parseString(code);

            t1 = Sys.time();
            for (i in 0...1000) {
                var result = interp.execute(ast);
            }
            t2 = Sys.time();
            Sys.println("HSCRIPT-REWRITE Execution Time (1000 runs): " + ((t2 - t1)) + " seconds");

            // Save packed bytecode
            var bytes:Bytes = Packer.pack(instructions);
            File.saveBytes("test.nh", bytes);

        } catch (e:Dynamic) {
            Sys.println(e);
        }
    }
}