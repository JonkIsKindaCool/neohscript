package hscript.ast.statements;

import hscript.ast.expressions.Expression;
import hscript.ast.Extras.ASTFunction;
import hscript.ast.statements.Statement;

enum StatementKind {
    BlockStmt(b:Array<Statement>);

    FunctionStmt(f:ASTFunction);
    IFStmt(c:Expression, b:Statement, ?e:Statement);
    ReturnStmt(?r:Expression);
    ThrowStmt(b:StatementKind);
}