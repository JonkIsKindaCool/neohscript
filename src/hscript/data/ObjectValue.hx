package hscript.data;

import hscript.ast.expressions.Expression;

@:structInit
class ObjectValue {
    public var name:String;
    public var value:Expression;
}