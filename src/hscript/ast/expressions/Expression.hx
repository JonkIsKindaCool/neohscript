package hscript.ast.expressions;

import hscript.ast.expressions.ExpressionKind.Access;

@:structInit
class Expression {
	public var kind:ExpressionKind;
	public var span:Span;

	public function toString():String {
		return Std.string(kind);
	}
}
