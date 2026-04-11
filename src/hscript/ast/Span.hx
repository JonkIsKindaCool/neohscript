package hscript.ast;

@:structInit
class Span {
    public var file:String;

    public var line:Int;
    public var start:Int;
    public var end:Int;
}

@:structInit
class ComplexSpan {
    public var file:String;

    public var start:Span;
    public var end:Span;
}