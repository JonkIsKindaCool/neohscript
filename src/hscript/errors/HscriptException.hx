package hscript.errors;

import hscript.ast.Span;
import haxe.Exception;

class HscriptException extends Exception {
    public var pos:Span;
    
    public function new(message:String, pos:Span) {
        this.pos = pos;
        super(message);
    }
}