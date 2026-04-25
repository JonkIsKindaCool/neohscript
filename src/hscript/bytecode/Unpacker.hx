package hscript.bytecode;

import haxe.io.BytesInput;
import haxe.io.Bytes;

class Unpacker {
    public static function unpack(bytes:Bytes):Program {
        var input:BytesInput = new BytesInput(bytes);
        var p:Program = {
            instructions: [],
            constantPool: [],
            filename: "<unnamed>"
        };

        var headerLen:Int = input.readInt16();
        var header:String = input.readString(headerLen);

        if (header != "NEOHSCRIPT")
            throw 'Uncompatible binary file.';

        var versionLen:Int = input.readInt16();
        var version:String = input.readString(versionLen);

        var nameLen:Int = input.readInt16();
        var filename:String = input.readString(nameLen);

        p.filename = filename;

        while (true){
            switch (input.readByte()){
                case 0:
                    p.constantPool.push(input.readInt16());
                case 1:
                    p.constantPool.push(input.readFloat());
                case 2:
                    var len:Int = input.readInt16();
                    p.constantPool.push(input.readString(len));
                case _:
                    break;
            }
        }

        var len:Int = input.readInt16();
        for (i in 0...len){
            p.instructions.push(input.readByte());
        }

        return p;
    }
}