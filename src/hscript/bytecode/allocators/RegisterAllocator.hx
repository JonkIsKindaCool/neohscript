package hscript.bytecode.allocators;

import haxe.ds.GenericStack;
import haxe.ds.Vector;

class RegisterAllocator {
	public var used(get, never):Vector<Bool>;
	public var currentRegister:Int;

	private var _previousStates:GenericStack<Vector<Bool>>;

	public function new() {
		_previousStates = new GenericStack();
		currentRegister = 0;

		pushScope();
	}

	public function pushScope() {
		_previousStates.add(used.copy());
	}

	public function popScope() {
		_previousStates.pop();
	}

	public function allocateRegister():Int {
		// 8 bits limit
		if (currentRegister >= 256) {
			throw 'Max amount of registers reached.';
		}

		for (i in currentRegister...256) {
			if (!used[i]){
                used[i] = true;
                currentRegister = i;
                return i;
            }
		}

		throw 'All the registers has been used.';
	}

	public function free(reg:Int) {
		if (!used[reg])
			throw 'Trying to free an already empty register.';

		if (reg < currentRegister)
			currentRegister = reg;

		used[reg] = false;
	}

	private function get_used():Vector<Bool> {
		return _previousStates?.head?.elt ?? new Vector(255, false);
	}
}
