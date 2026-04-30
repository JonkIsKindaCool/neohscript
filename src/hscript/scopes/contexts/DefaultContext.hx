package hscript.scopes.contexts;

import hscript.data.Types;
import haxe.Rest;

class DefaultContext implements Context {
	public var globals:Scope;

	public function new() {
		globals = new Scope();

		for (name => variable in NeoHscript.DEFAULT_IMPORTS)
			defineVariable(name, variable);
	}

	public function getVariable(name:String):Dynamic {
		return globals.get(name);
	}

	public function defineVariable(name:String, value:Dynamic, ?type:Types, ?const:Bool) {
		globals.define(name, value, type, const);
	}

	public function setVariable(name:String, value:Dynamic):Dynamic {
		return globals.set(name, value);
	}

	public function callFunction(name:String, args:Rest<Dynamic>):Dynamic {
		return globals.callFunction(name, args);
	}
}
