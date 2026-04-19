package hscript.bytecode.allocators;

import haxe.ds.GenericStack;

class VariableAllocator {
	public var variables(get, never):Map<String, Int>;

	private var _previousStates:GenericStack<Map<String, Int>>;

	public function new() {
        _previousStates = new GenericStack();

        pushScope();
    }

    public function pushScope() {
        _previousStates.add(variables.copy());
    }

    public function popScope() {
        _previousStates.pop();
    }

	public function setVariable(name:String, reg:Int) {
		variables.set(name, reg);
	}

	public function getVariable(name:String):Int {
		return variables.get(name);
	}

    private function get_variables():Map<String, Int>{
        return _previousStates?.head?.elt ?? new Map<String, Int>();
    }
}
