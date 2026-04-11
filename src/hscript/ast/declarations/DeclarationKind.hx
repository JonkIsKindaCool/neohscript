package hscript.ast.declarations;

import hscript.ast.expressions.Expression;
import hscript.ast.Extras.ASTFunction;

enum DeclarationKind {
    VarDecl(n:String, e:Expression, ?constant:Bool);
    FunctionDecl(f:ASTFunction);
}