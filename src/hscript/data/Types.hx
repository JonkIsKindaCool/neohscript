package hscript.data;

enum Types {
	TSimple(name:String, ?generics:Array<Types>);

	TAnonymous(fields:Array<AnonymousValue>);

	TFunction(args:Array<Types>, ret:Types);

	TOptional(inner:Types);

	TDynamic(?constraint:Types);
}