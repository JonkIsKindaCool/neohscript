package hscript.bytecode.allocators;

import hscript.ast.expressions.Expression;
import hscript.bytecode.Instruction;
import hscript.ast.expressions.ExpressionKind.ASTType;
import haxe.ds.GenericStack;

typedef Variable = {
	reg:Int,
	type:ASTType,
	const:Bool
}

typedef Inline = {
    body: Expression,
    type:ASTType,
    const:Bool
} 

private typedef VariableAllocatorState = {
	variables:Map<String, Variable>,
	inlines:Map<String, Inline>
}

@:access(hscript.bytecode.Compiler)
class VariableAllocator {
	public var variables(get, never):Map<String, Variable>;
	public var inlines(get, never):Map<String, Inline>;

	private var _previousStates:GenericStack<VariableAllocatorState>;
	private var _currentReg:Int = 0;

    private var compiler:Compiler;

	public function new(c:Compiler) {
		_previousStates = new GenericStack();

        this.compiler = c;

		pushScope();
	}

	public function pushScope() {
		_previousStates.add({
			variables: variables.copy(),
			inlines: inlines.copy()
		});
	}

	public function popScope() {
		_previousStates.pop();
	}

	public function exists(name:String):Bool {
		return inlines.exists(name) || variables.exists(name);
	}

    public function isInline(name:String):Bool {
        return inlines.exists(name);
    }

    public function setInline(name:String, e:Expression, const:Bool, type:ASTType) {
        inlines.set(name, {
            body: e,
            const: const,
            type: type
        });
    }

    public function getInline(name:String):Expression {
        return inlines.get(name).body;
    }

	public function setVariable(name:String, const:Bool, ?type:ASTType):Int {
		variables.set(name, {
			const: const,
			reg: _currentReg,
			type: type
		});
		return _currentReg++;
	}

	public function getVariable(name:String):Int {
		return variables.get(name).reg;
	}

	private function get_variables():Map<String, Variable> {
		return _previousStates?.head?.elt.variables ?? new Map<String, Variable>();
	}

	private function get_inlines():Map<String, Inline> {
		return _previousStates?.head?.elt.inlines ?? new Map<String, Inline>();
	}
}
