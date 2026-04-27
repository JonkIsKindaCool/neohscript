package hscript.scopes.contexts;

import haxe.Rest;
import hscript.ast.expressions.ExpressionKind.ASTType;

interface Context {
    public function getVariable(name:String):Dynamic;
    public function setVariable(name:String, value:Dynamic, ?type:ASTType, ?const:Bool):Dynamic;

    public function callFunction(name:String, args:Rest<Dynamic>):Dynamic;
}