package hscript.bytecode;

import hscript.ast.Span;

@:structInit
class Program {
    public var bytes:Array<Byte>;
    public var constants:Array<Dynamic>;
    public var positions:Array<Span>;

    public static function getConstans(arr:Array<Dynamic>):String {
        var buf:StringBuf = new StringBuf();

        for (c in arr)
            buf.add(Std.string(c) + "'\n");

        return buf.toString();
    }

    public static function getBytecodeRepresentation(bytes:Array<Byte>):String {
        var buf:StringBuf = new StringBuf();

        var pc:Int = 0;

        while (pc < bytes.length){
            switch (bytes[pc++]){
                case GET_CONSTANT:
                    buf.add('LOADK ${bytes[pc++]}\n');

                case OP_ADD:
                    buf.add('ADD\n');
                case OP_SUB:
                    buf.add('SUB\n');
                case OP_MULT:
                    buf.add('MULT\n');
                case OP_DIV:
                    buf.add('DIV\n');
                case OP_MOD:
                    buf.add('MOD\n');
                case OP_NEG:
                    buf.add('NEG\n');
                case OP_EQUAL:
                    buf.add('EQ\n');
                case OP_NOT_EQUAL:
                    buf.add('NOT_EQ\n');
                case OP_GT:
                    buf.add('GT\n');
                case OP_GTE:
                    buf.add('GTE\n');
                case OP_LT:
                    buf.add('LT\n');
                case OP_LTE:
                    buf.add('LTE\n');
                case OP_BOOL_AND:
                    buf.add('BOOL_AND\n');
                case OP_BOOL_OR:
                    buf.add('BOOL_OR\n');
                case OP_NOT:
                    buf.add('NOT\n');
                case OP_AND:
                    buf.add('OP_AND\n');
                case OP_OR:
                    buf.add('OR\n');
                case OP_XOR:
                    buf.add('XOR\n');
                case OP_SHL:
                    buf.add('SHL\n');
                case OP_SHR:
                    buf.add('SHR\n');
                case OP_USHR:
                    buf.add('USHR\n');
                case OP_INTERVAL:
                    buf.add('INTERVAL\n');
            }
        }

        return buf.toString();
    }
}