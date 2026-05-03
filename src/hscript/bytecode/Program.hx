package hscript.bytecode;

import hscript.ast.Span;

@:structInit
class Program {
    public var bytes:Array<Byte>;
    public var constants:Array<Dynamic>;
    public var positions:Array<Span>;
}