package hscript.ast;

@:structInit
class Span {
    public var line:Int;
    public var start:Int;
    public var end:Int;
}

@:structInit
class ComplexSpan {
    public var start:Span;
    public var end:Span;
}