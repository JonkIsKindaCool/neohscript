import haxe.ds.GenericStack;
import hscript.Parser;
import haxe.Resource;
import hscript.lexer.Lexer;
import hscript.lexer.Token;

@:access(hscript.Parser)
class Main {
	static function main() {
		var tokens:Array<Token> = Lexer.tokenify(Resource.getString("test.hx"));
	}
}
