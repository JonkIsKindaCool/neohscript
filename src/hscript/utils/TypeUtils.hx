package hscript.utils;

import haxe.DynamicAccess;
import hscript.data.Types;
import Type.ValueType;

class TypeUtils {
	public static function getHaxeTypeName(t:ValueType, value:Dynamic):String {
		return switch (t) {
			case TNull: "Null";
			case TInt: "Int";
			case TFloat: "Float";
			case TBool: "Bool";
			case TFunction: "(Function)";
			case TUnknown: "Unknown";
			case TClass(c): Type.getClassName(c) ?? "Unknown";
			case TEnum(e): e.getName();
			case TObject:
				try {
					var obj:DynamicAccess<Dynamic> = value;
					var keys = [for (k in obj.keys()) k];
					if (keys.length == 0)
						return "{}";
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
		if (t == null)
			return "Dynamic";
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

	public static function isCompatible(value:Dynamic, expected:Types):Bool {
		if (expected == null)
			return true;

		if (!NeoHscript.STATIC_TYPING)
			return true;

		switch (expected) {
			case TDynamic(_):
				return true; 

			case TSimple("Dynamic", _):
				return true;

			case TSimple("Void", _):
				return true;

			case TOptional(inner):
				return value == null || isCompatible(value, inner);

			case TSimple("Null", generics) if (generics != null && generics.length > 0):
				return value == null || isCompatible(value, generics[0]);

			case _:
				if (value == null)
					return false;
		}

		switch (expected) {
			case TSimple(name, generics):
				return switch (name) {
					case "Int":
						Std.isOfType(value, Int);

					case "UInt": 
						Std.isOfType(value, Int) && (value : Int) >= 0;

					case "Float": 
						Std.isOfType(value, Float) || Std.isOfType(value, Int);

					case "Bool":
						Std.isOfType(value, Bool);

					case "String":
						Std.isOfType(value, String);

					case "Array":
						if (!Std.isOfType(value, Array))
							return false;
						if (generics == null || generics.length == 0)
							return true;
						var elemType = generics[0];
						if (elemType.equals(TSimple("Dynamic")) || elemType.match(TDynamic(_)))
							return true;
						var arr:Array<Dynamic> = value;
						for (elem in arr)
							if (!isCompatible(elem, elemType))
								return false;
						return true;

					case "Map":
						return Reflect.isFunction(Reflect.field(value, "get"))
							&& Reflect.isFunction(Reflect.field(value, "set"))
							&& Reflect.isFunction(Reflect.field(value, "exists"))
							&& Reflect.isFunction(Reflect.field(value, "keys"))
							&& Reflect.isFunction(Reflect.field(value, "remove"));

					case "Iterable":
						return Reflect.isFunction(Reflect.field(value, "iterator"));

					case "Iterator":
						return Reflect.isFunction(Reflect.field(value, "hasNext")) && Reflect.isFunction(Reflect.field(value, "next"));

					case _:
						try {
							var cls = Type.resolveClass(name);
							if (cls != null)
								return Std.isOfType(value, cls);
						} catch (_:Dynamic) {}

						try {
							var enm = Type.resolveEnum(name);
							if (enm != null) {
								return switch (Type.typeof(value)) {
									case TEnum(e): e == enm;
									default: false;
								};
							}
						} catch (_:Dynamic) {}

						return false;
				};

			case TAnonymous(fields):
				for (f in fields) {
					var fieldExists = Reflect.hasField(value, f.name);

					if (!fieldExists) {
						if (f.optional == true)
							continue;
						return false;
					}

					var fieldVal:Dynamic = Reflect.field(value, f.name);
					if (!isCompatible(fieldVal, f.type))
						return false;
				}
				return true;

			case TFunction(_, _):
				return Reflect.isFunction(value);

			case TDynamic(_):
				return true;
			case TOptional(_):
				return true;

			case _:
				return false;
		}
	}
}
