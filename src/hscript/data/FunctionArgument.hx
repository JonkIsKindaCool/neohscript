package hscript.data;

import hscript.ast.expressions.Expression;

@:structInit
class FunctionArgument {
	public var name:String;
	public var type:Types;
	public var optional:Bool;

	public var def:Expression;

	public function toString():String {
		return '${optional ? '?' : ''}$name:$type${def != null ? ' = $def' : ''}';
	}
}