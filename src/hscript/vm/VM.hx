package hscript.vm;

import hscript.bytecode.Instruction;
import hscript.bytecode.Program;
import haxe.ds.Vector;

/**
	Register Based VM.
	It uses 3 tables, one for registers, one for variables and another for constants.
**/
class VM {
	private var registers:Array<Dynamic>;
	private var constants:Array<Dynamic>;
	private var variables:Array<Dynamic>;

	private var instructions:Array<Instruction>;
	private var pc:Int;

	public function new() {}

	public function execute(p:Program):Dynamic {
		registers = [];
		instructions = p.instructions;
		constants = p.constantPool;
		pc = 0;

		var last:Dynamic = null;
		while (pc < instructions.length)
			last = executeInstruction(getInstruction());

		return last;
	}

	private function executeInstruction(i:Instruction):Dynamic {
		switch (i) {
			case LOAD_CONSTANT:
				var reg:Int = getInstruction();
				var const:Int = getInstruction();
				return registers[reg] = constants[const];
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
