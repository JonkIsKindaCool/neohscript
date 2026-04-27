package hscript.scopes.contexts;

import hscript.ast.expressions.ExpressionKind.ASTType;
import haxe.Rest;

class DefaultContext implements Context {
    public var globals:Scope;

    public function callFunction(name:String, arg:Rest<Dynamic>):Dynamic {
        throw new haxe.exceptions.NotImplementedException();
    }

    public function setVariable(name:String, value:Dynamic, ?type:ASTType, ?const:Bool):Dynamic {
        throw new haxe.exceptions.NotImplementedException();
    }

    public function getVariable(name:String):Dynamic {
        throw new haxe.exceptions.NotImplementedException();
    }

        
}