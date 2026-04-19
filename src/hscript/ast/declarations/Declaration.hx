package hscript.ast.declarations;

import hscript.ast.expressions.ExpressionKind.Access;
import hscript.ast.Span.ComplexSpan;

@:structInit
class Declaration {
    public var kind:DeclarationKind;
    public var span:ComplexSpan;
    public var access:Array<Access>;
    
    public function toString():String {
        return Std.string(kind);
    }
}