package hscript.utils;

import haxe.DynamicAccess;
import hscript.data.Types;
import Type.ValueType;

class TypeUtils {
	public static function getHaxeTypeName(t:ValueType, value:Dynamic):String {
		switch (t) {
			case TNull:
				return 'Null';
			case TInt:
				return 'Int';
			case TFloat:
				return 'Float';
			case TBool:
				return 'Bool';
			case TObject:
				var buf:StringBuf = new StringBuf();

				buf.add("{");

				var v:DynamicAccess<Dynamic> = value;

				for (name => value in v) {
					buf.add(name);
					buf.add(": ");
					buf.add(getHaxeTypeName(Type.typeof(value), value));

					if (v.keys()[Lambda.count(v.keys()) - 1] != name)
						buf.add(", ");
				}

				buf.add("}");

				return buf.toString();
			case TFunction:
				return 'Function';
			case TClass(c):
				return Type.getClassName(c);
			case TEnum(e):
				return e.getName();
			case TUnknown:
				return 'Unknown';
		}
	}

	public static function getHScriptType(t:Types):String {
		switch (t) {
			case TSimple(name, generics):
				return name;
			case TAnonymous(v):
				var buf:StringBuf = new StringBuf();

				buf.add("{");
				for (i => value in v) {
					buf.add(value.name);
					buf.add(": ");
					buf.add(getHScriptType(value.type));
					if (i != v.length - 1)
						buf.add(", ");
				}
				buf.add("}");

				return buf.toString();
			case TFunction(variables, ret):
				return 'Function';
		}
	}
}
