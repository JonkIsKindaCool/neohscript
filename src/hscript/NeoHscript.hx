package hscript;

import haxe.Log;
import haxe.PosInfos;

@:access(hscript.bytecode.Compiler)
@:access(hscript.vm.VM)
class NeoHscript {
	public static var STRICT_SEMICOLONS:Bool = true;
	public static var STATIC_TYPING:Bool = true;

	public static var DEFAULT_IMPORTS:Map<String, Dynamic> = [
		"trace" => function(a:Dynamic, pos:PosInfos) {
			Log.trace(a, pos);
		},
		'Reflect' => Reflect,
		'Std' => Std,
		'Math' => Math,
		#if sys 'Sys' => Sys, #end
		'Type' => Type,
		'StringTools' => StringTools,
		'Date' => Date,
		'DateTools' => DateTools,
		'Xml' => Xml,
		'Int' => Int,
		'String' => String,
		'StringBuf' => StringBuf,
		'Float' => Float,
		'Bool' => Bool,
		'Array' => Array,
		'Lambda' => Lambda,
		'EReg' => EReg
	];
}
