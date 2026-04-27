package hscript.scopes;

import haxe.Rest;
import hscript.ast.expressions.ExpressionKind.ASTType;
import haxe.ds.StringMap;

class Scope {
	public var parent:Scope;
	public var variables:StringMap<VariableSlot>;

	public function new(?scope:Scope) {
		this.parent = scope;

		variables = new StringMap();
	}

	public function define(name:String, value:Dynamic, ?type:ASTType, ?const:Bool = false) {
		variables.set(name, {
			value: value,
			type: type,
			const: const
		});
	}

	public function set(name:String, value:Dynamic):Dynamic {
		if (parent != null && parent.exists(name))
			return parent.set(name, value);

		if (!variables.exists(name))
			throw 'Variable $name doesnt exists';

		var v:VariableSlot = variables.get(name);

		if (v.const)
			throw 'Cannot modify the value of constant $name';

		return v.value = value;
	}

	public function get(name:String):Dynamic {		
		if (parent != null && parent.exists(name))
			return parent.get(name);

		if (!variables.exists(name))
			throw 'Variable $name doesnt exists';

		return variables.get(name).value;
	}

	public function exists(name:String):Bool {
		if (parent != null && parent.exists(name))
			return true;

		return variables.exists(name);
	}

	public function callFunction(name:String, args:Rest<Dynamic>):Dynamic {
		var f:Dynamic = get(name);

		if (Reflect.isFunction(f)) {
			if (args.length <= 0)
				return f();
			else {
				return Reflect.callMethod(null, f, args);
			}
		}

		throw 'Cannot call a non-function';
	}
}

@:structInit
private class VariableSlot {
	public var value:Dynamic;
	public var type:ASTType;
	public var const:Bool;
}
