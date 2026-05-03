package hscript.utils;

import haxe.DynamicAccess;
import hscript.data.Types;
import Type.ValueType;

class TypeUtils {
	public static function getHaxeTypeName(t:ValueType, value:Dynamic):String {
		return switch (t) {
			case TNull:     "Null";
			case TInt:      "Int";
			case TFloat:    "Float";
			case TBool:     "Bool";
			case TFunction: "(Function)";
			case TUnknown:  "Unknown";
			case TClass(c): Type.getClassName(c) ?? "Unknown";
			case TEnum(e):  e.getName();
			case TObject:
				try {
					var obj:DynamicAccess<Dynamic> = value;
					var keys = [for (k in obj.keys()) k];
					if (keys.length == 0) return "{}";
					var parts = [
						for (k in keys)
							'$k: ${getHaxeTypeName(Type.typeof(obj.get(k)), obj.get(k))}'
					];
					"{ " + parts.join(", ") + " }";
				} catch (_) {
					"{}";
				}
		};
	}

	public static function typeToString(t:Types):String {
		if (t == null) return "Dynamic";
		return switch (t) {
			case TSimple(name, null) | TSimple(name, []):
				name;
			case TSimple(name, generics):
				'$name<${generics.map(typeToString).join(", ")}>';

			case TAnonymous([]):
				"{}";
			case TAnonymous(fields):
				var parts = [
					for (f in fields)
						'${(f.optional == true) ? "?" : ""}${f.name}: ${typeToString(f.type)}'
				];
				"{ " + parts.join(", ") + " }";

			case TFunction([], ret):
				"() -> " + typeToString(ret);
			case TFunction([single], ret):
				typeToString(single) + " -> " + typeToString(ret);
			case TFunction(args, ret):
				"(" + args.map(typeToString).join(", ") + ") -> " + typeToString(ret);

			case TOptional(inner):
				"Null<" + typeToString(inner) + ">";

			case TDynamic(null):
				"Dynamic";
			case TDynamic(c):
				"Dynamic<" + typeToString(c) + ">";
		};
	}
}