package hscript.lexer;

@:structInit
class Token {
    public var start:Int;
    public var end:Int;
    public var line:Int;

    public var kind:TokenKind;
}