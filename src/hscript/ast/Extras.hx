package hscript.ast;

import hscript.ast.expressions.Expression;
import haxe.ds.GenericStack;

/**
    Why this is a thing, so basically there are things that in haxe can work as expression and statements at the same time
    like functions so this will help for making things like functions easier
**/

@:structInit
class ASTFunction {
    public var name:Null<String>;

    //testing if this could work
    public var arguments:GenericStack<FunctionArgument>;
    public var retType:ASTType;

    public var body:Expression;
}

@:structInit
class ASTVarDecl {
    public var name:Null<String>;
    public var type:Null<ASTType>;

    public var isConst:Bool;
    public var expr:Null<Expression>;
}

@:structInit
class FunctionArgument {
    public var name:String;
    public var type:ASTType;
    public var optional:Bool;

    public var def:Expression;
}

@:structInit
class ASTType {
    public var name:String;
    public var generics:Array<ASTType>;
}