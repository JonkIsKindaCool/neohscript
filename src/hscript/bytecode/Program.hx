package hscript.bytecode;

@:structInit
class Program {
    public var instructions:Array<Instruction>;
    public var constantPool:Array<Dynamic>;
}