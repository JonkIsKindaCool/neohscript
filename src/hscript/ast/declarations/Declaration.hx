package hscript.ast.declarations;

import hscript.ast.Span.ComplexSpan;

@:structInit
class Declaration {
    public var kind:DeclarationKind;
    public var span:ComplexSpan;
}