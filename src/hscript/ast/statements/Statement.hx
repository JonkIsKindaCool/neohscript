package hscript.ast.statements;

import hscript.ast.Span.ComplexSpan;

@:structInit
class Statement {
    public var kind:StatementKind;
    public var span:ComplexSpan;
}