package hscript.ast;

@:structInit
class Span {
    public var file:String;

    public var line:Int;
    public var start:Int;
    public var end:Int;

    public function new(file:String, line:Int, start:Int, end:Int) {
        this.file = file;
        this.line = line;
        this.start = start;
        this.end = end;
    }
}