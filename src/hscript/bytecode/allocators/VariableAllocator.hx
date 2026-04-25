package hscript.bytecode.allocators;

import hscript.ast.expressions.ExpressionKind.ASTType;
import haxe.ds.GenericStack;

typedef Variable = {
	reg:Int,
	type:ASTType,
	const:Bool
}

private typedef Scope = {
	variables:Map<String, Variable>,
}

@:access(hscript.bytecode.Compiler)
class VariableAllocator {
	public var variables(get, never):Map<String, Variable>;

	private var _scopes:GenericStack<Scope>;
	private var _currentReg:Int = 0;
	private var compiler:Compiler;

	public function new(c:Compiler) {
		_scopes  = new GenericStack();
		compiler = c;
		pushScope();
	}

	public function pushScope() {
		_scopes.add({variables: variables.copy()});
	}

	public function popScope() {
		_scopes.pop();
	}

	public function exists(name:String):Bool {
		return variables.exists(name);
	}

	public function setVariable(name:String, const:Bool, ?type:ASTType):Int {
		var slot:Int = _currentReg++;
		variables.set(name, {const: const, reg: slot, type: type});
		return slot;
	}

	public function declareVariable(name:String, const:Bool, ?type:ASTType):Int {
		if (variables.exists(name))
			return variables.get(name).reg;
		return setVariable(name, const, type);
	}

	public function getVariable(name:String):Int {
		return variables.get(name).reg;
	}

	private function get_variables():Map<String, Variable> {
		return _scopes?.head?.elt.variables ?? new Map<String, Variable>();
	}
}