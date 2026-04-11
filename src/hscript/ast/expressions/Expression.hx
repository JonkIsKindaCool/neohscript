package hscript.ast.expressions;

@:structInit
class Expression {
	public var kind:ExpressionKind;
	public var span:Span;

	public function toString():String {
		return Std.string(kind);
	}
}
