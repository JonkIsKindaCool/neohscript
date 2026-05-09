package hscript.contexts;

import haxe.Rest;

class DefaultContext implements Context {
	public var variables:Map<String, Dynamic>;

	public function new() {
		variables = new Map();
		
		for (name => variable in NeoHscript.DEFAULT_IMPORTS)
			defineVariable(name, variable);
	}

	public function getVariable(name:String):Dynamic {
		return variables.get(name);
	}

	public function defineVariable(name:String, value:Dynamic, ?type:Types, ?const:Bool) {
		variables.set(name, value);
	}

	public function setVariable(name:String, value:Dynamic):Dynamic {
		variables.set(name, value);
		return value;
	}

	public function callFunction(name:String, args:Rest<Dynamic>):Dynamic {
		var f = variables.get(name);
		if (args.length > 0){
			return Reflect.callMethod(null, f, args);
		}
		return f();
	}
}