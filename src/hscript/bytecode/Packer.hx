package hscript.bytecode;

import haxe.io.BytesOutput;
import haxe.io.Bytes;

class Packer {
	public static function pack(p:Program):Bytes {
		var bytes:BytesOutput = new BytesOutput();

        bytes.writeInt16("NEOHSCRIPT".length);
		bytes.writeString("NEOHSCRIPT");
        bytes.writeInt16("1.0.0".length);
		bytes.writeString("1.0.0");

		for (constant in p.constantPool) {
			switch (Type.typeof(constant)) {
				case TInt:
					bytes.writeByte(0);
					bytes.writeInt16(constant);
				case TFloat:
					bytes.writeByte(1);
					bytes.writeFloat(constant);
				case TClass(c):
					if (Std.isOfType(constant, String)) {
						bytes.writeByte(2);
						bytes.writeInt16((constant : String).length);
						bytes.writeString(constant);
					} else
						throw 'Unsopported Type for packing.';
				case _:
					throw 'Unsopported Type for packing.';
			}
		}
        bytes.writeByte(0xFF);

        bytes.writeInt16(p.instructions.length);
        for (i in p.instructions){
            bytes.writeByte(i);
        }

		return bytes.getBytes();
	}
}
