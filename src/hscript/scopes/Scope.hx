package hscript.scopes;

import hscript.utils.TypeUtils;
import hscript.data.Types;
import haxe.Rest;
import haxe.ds.StringMap;

class Scope {
	public var parent:Scope;
	public var variables:StringMap<VariableSlot>;

	public function new(?parent:Scope) {
		this.parent = parent;
		variables = new StringMap();
	}

	public function define(name:String, value:Dynamic, ?type:Types, ?isConst:Bool = false) {
		if (!TypeUtils.isCompatible(value, type)) {
			var got = TypeUtils.getHaxeTypeName(Type.typeof(value), value);
			var exp = TypeUtils.typeToString(type);
			throw 'Type error: cannot assign $got to "$name" of type $exp';
		}
		variables.set(name, {value: value, type: type, isConst: isConst});
	}

	public function set(name:String, value:Dynamic):Dynamic {
		if (variables.exists(name)) {
			var slot = variables.get(name);

			if (slot.isConst)
				throw 'Cannot reassign final variable "$name"';

			if (!TypeUtils.isCompatible(value, slot.type)) {
				var got = TypeUtils.getHaxeTypeName(Type.typeof(value), value);
				var exp = TypeUtils.typeToString(slot.type);
				throw 'Type error: cannot assign $got to "$name" of type $exp';
			}

			slot.value = value;
			return value;
		}

		if (parent != null)
			return parent.set(name, value);

		throw 'Variable "$name" is not defined';
	}

	public function get(name:String):Dynamic {
		if (variables.exists(name))
			return variables.get(name).value;

		if (parent != null)
			return parent.get(name);

		throw 'Variable "$name" is not defined';
	}

	public function exists(name:String):Bool {
		return variables.exists(name) || (parent != null && parent.exists(name));
	}

	public function existsLocally(name:String):Bool {
		return variables.exists(name);
	}

	public function getType(name:String):Null<Types> {
		if (variables.exists(name))
			return variables.get(name).type;
		if (parent != null)
			return parent.getType(name);
		return null;
	}

	public function callFunction(name:String, args:Rest<Dynamic>):Dynamic {
		var f:Dynamic = get(name);
		if (!Reflect.isFunction(f))
			throw '"$name" is not callable';
		return Reflect.callMethod(null, f, args.toArray());
	}
}

@:structInit
private class VariableSlot {
	public var value:Dynamic;
	public var type:Types;
	public var isConst:Bool;
}