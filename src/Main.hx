import hscript.Parser;
import hscript.ast.Parser;
import haxe.macro.Expr;
import haxe.ds.GenericStack;
import haxe.Resource;
import hscript.lexer.Lexer;
import hscript.lexer.Token;

@:access(hscript.Parser)
class Main {
	static function main() {
		var tokens:Array<Token> = Lexer.tokenify(Resource.getString("Test.hx"));
	}
}
