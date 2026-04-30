package hscript.scopes.contexts;

import hscript.data.Types;
import haxe.Rest;

interface Context {
	public var globals:Scope;

	public function getVariable(name:String):Dynamic;
	public function defineVariable(name:String, value:Dynamic, ?type:Types, ?const:Bool):Void;
	public function setVariable(name:String, value:Dynamic):Dynamic;

	public function callFunction(name:String, args:Rest<Dynamic>):Dynamic;
}
