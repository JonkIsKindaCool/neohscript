package hscript.data;

import hscript.data.AnonymousValue;

enum Types {
    TSimple(name:String, ?generics:Array<Types>);
    TAnonymous(v:Array<AnonymousValue>);
    TFunction(variables:Array<Types>, ret:Types);
}