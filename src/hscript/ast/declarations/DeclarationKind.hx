package hscript.ast.declarations;

import hscript.ast.expressions.ExpressionKind.ASTType;
import hscript.ast.expressions.Expression;

enum DeclarationKind {
    DExpr(e:Expression);
    DVar(n:String, f:Bool, ?e:Expression, ?t:ASTType);
}