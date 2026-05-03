package hscript.bytecode.runtime;

import haxe.DynamicAccess;
import hscript.errors.HscriptException;
import haxe.Exception;
import hscript.ast.Span;

class Interpreter {
	private var _bytes:Array<Byte>;
	private var _constants:Array<Dynamic>;
	private var _positions:Array<Span>;

	private var _programCounter:Int;
	private var _positionCounter:Int;

	private var _position:Span;

	public function new() {}

	public function execute(p:Program) {
		_bytes = p.bytes;
		_constants = p.constants;
		_positions = p.positions;

		_programCounter = 0;
		_positionCounter = 0;

		var last:Dynamic = null;

		while (_programCounter < _bytes.length)
			last = executeByte(getInstruction());

		return last;
	}

	private function executeByte(b:Byte):Dynamic {
		_position = _positions[_positionCounter++];

		try {
			return switch (b) {
				case GET_CONSTANT:
					return getConstant();
				case GET_VARIABLE:
					null;
				case TRUE:
					true;
				case FALSE:
					false;
				case NULL:
					null;
				case ARRAY:
					var len:Int = getInstruction();
					var arr:Array<Dynamic> = [];
					for (_ in 0...len)
						arr.push(executeByte(getInstruction()));
					return arr;
				case OBJECT:
					var len:Int = getInstruction();
					var obj:DynamicAccess<Dynamic> = {};
					for (_ in 0...len) {
						obj.set(getConstant(), executeByte(getInstruction()));
					}

					return obj;
				case OP_ADD:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l + r;
				case OP_SUB:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l - r;
				case OP_MULT:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l * r;
				case OP_DIV:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l / r;
				case OP_MOD:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l % r;
				case OP_NEG:
					var v:Dynamic = executeByte(getInstruction());
					- v;
				case OP_EQUAL:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l == r;
				case OP_NOT_EQUAL:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l != r;
				case OP_GT:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l > r;
				case OP_GTE:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l >= r;
				case OP_LT:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l < r;
				case OP_LTE:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					l <= r;
				case OP_BOOL_AND: var l:Dynamic = executeByte(getInstruction()); var r:Dynamic = executeByte(getInstruction()); l && r;

				case OP_BOOL_OR: var l:Dynamic = executeByte(getInstruction()); var r:Dynamic = executeByte(getInstruction()); l || r;

				case OP_NOT:
					var v:Dynamic = executeByte(getInstruction());
					!v;
				case OP_AND:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					return l & r;
				case OP_OR:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					return l | r;
				case OP_XOR:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					return l ^ r;
				case OP_SHL:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					return l << r;
				case OP_SHR:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					return l >> r;
				case OP_USHR:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					return l >>> r;
				case OP_INTERVAL:
					var l:Dynamic = executeByte(getInstruction());
					var r:Dynamic = executeByte(getInstruction());

					return l...r;
			}
		} catch (e:Exception) {
			throw new HscriptException(e.message, _position);
		}
	}

	private inline function getInstruction():Byte {
		return _bytes[_programCounter++];
	}

	private inline function getConstant():Dynamic {
		return _constants[getInstruction()];
	}
}
