package hscript.vm;

import haxe.PosInfos;
import hscript.bytecode.Instruction;
import hscript.bytecode.Program;
import haxe.ds.Vector;

/**
	Register Based VM.
	It uses 3 tables, one for registers, one for variables and another for constants.
**/
class VM {
	private var variableTable:Map<String, Int>;
	private var registers:Array<Dynamic>;
	private var constants:Array<Dynamic>;
	private var variables:Array<Dynamic>;

	private var instructions:Array<Instruction>;
	private var pc:Int;

	public function new() {
		variableTable = new Map();
	}

	public function execute(p:Program):Dynamic {
		variableTable = new Map();

		registers = [];
		variables = [];

		instructions = p.instructions;
		constants = p.constantPool;
		pc = 0;

		var last:Dynamic = null;
		while (pc < instructions.length)
			last = executeInstruction(getInstruction());

		return last;
	}

	private function posInfos(name:String, line:Int, ?className:String):PosInfos {
		return {
			fileName: name,
			className: className,
			lineNumber: line,
			methodName: ""
		}
	}

	private function executeInstruction(i:Instruction):Dynamic {
		switch (i) {
			case LOAD_CONSTANT:
				var reg:Int = getInstruction();
				var const:Int = getInstruction();
				return registers[reg] = constants[const];
			case LOAD_LOCAL:
				var reg:Int = getInstruction();
				var local:Int = getInstruction();

				return registers[reg] = variables[local];

			case TRUE:
				var reg:Int = getInstruction();
				return registers[reg] = true;
			case FALSE:
				var reg:Int = getInstruction();
				return registers[reg] = false;
			case NULL:
				var reg:Int = getInstruction();
				return registers[reg] = null;

			case TOP_LEVEL_VAR_DECLARATION:
				var name:String = constants[getInstruction()];
				var pos:Int = getInstruction();
				var reg:Int = getInstruction();

				variables[pos] = registers[reg];
				variableTable.set(name, pos);
				return null;

			case OP_ADD:
				var l:Int = getInstruction();
				var r:Int = getInstruction();
				var t:Int = getInstruction();

				return registers[t] = registers[l] + registers[r];
			case OP_SUB:
				var l:Int = getInstruction();
				var r:Int = getInstruction();
				var t:Int = getInstruction();

				return registers[t] = registers[l] - registers[r];
			case OP_MULT:
				var l:Int = getInstruction();
				var r:Int = getInstruction();
				var t:Int = getInstruction();

				return registers[t] = registers[l] * registers[r];
			case OP_DIV:
				var l:Int = getInstruction();
				var r:Int = getInstruction();
				var t:Int = getInstruction();

				return registers[t] = registers[l] / registers[r];
			case OP_EQUAL:
				var l:Int = getInstruction();
				var r:Int = getInstruction();
				var t:Int = getInstruction();

				return registers[t] = registers[l] == registers[r];
			case _:
		}
		return null;
	}

	private inline function getInstruction():Int {
		return instructions[pc++];
	}
}
