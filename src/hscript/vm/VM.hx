package hscript.vm;

import haxe.Log;
import hscript.ast.Span;
import haxe.Exception;
import hscript.errors.HscriptException;
import haxe.PosInfos;
import hscript.bytecode.Instruction;
import hscript.bytecode.Program;

@:structInit
private class VariableSlot {
	public var value:Dynamic;
	public var type:String;
}

/**
	Register-based VM.

	Three storage tables:
	  • registers  – temporary values for expression evaluation
	  • variables  – named locals, indexed by slot allocated at compile time
	  • constants  – literal pool embedded in the bytecode
**/
class VM {
	private var variablesTable:Map<String, Int>;

	private var registers:Array<Dynamic>;
	private var constants:Array<Dynamic>;
	private var variables:Array<VariableSlot>;
	private var name:String;

	private var instructions:Array<Instruction>;
	private var pc:Int;

	private var returning:Bool = false;
	private var returnValue:Dynamic = null;

	public function new() {
		registers = [];
		variables = [];
		variablesTable = [];

		variables[0] = {
			value: function(a:Dynamic, pos:Span) {
				var pos:PosInfos = {
					fileName: pos.file,
					lineNumber: pos.line,
					className: "<unnamed>",
					methodName: "<unnamed>"
				};
				Log.trace(a, pos);
			},
			type: "Dynamic"
		}
	}

	public function execute(p:Program):Dynamic {
		name = p.filename;
		instructions = p.instructions;
		constants = p.constantPool;
		pc = 0;
		returning = false;

		var last:Dynamic = null;
		while (pc < instructions.length) {
			try {
				last = executeInstruction(getInstruction());
			} catch (e:Exception){
				throw e;
			}
		}

		return last;
	}

	public function getGlobal(name:String):Dynamic {
		return variables[variablesTable[name]];
	}

	private function executeInstruction(i:Instruction):Dynamic {
		var line:Int = getInstruction();
		var start:Int = getInstruction();
		var end:Int = getInstruction();
		try {
			switch (i) {
				case LOAD_CONSTANT:
					var reg:Int = getInstruction();
					var ci:Int = getInstruction();
					return registers[reg] = constants[ci];

				case LOAD_LOCAL:
					var reg:Int = getInstruction();
					var local:Int = getInstruction();
					return registers[reg] = variables[local].value;

				case STORE_LOCAL:
					var src:Int = getInstruction();
					var local:Int = getInstruction();
					var variable:VariableSlot = variables[local];

					if (isCompatible(registers[src], variable.type)) {
						variable.value = registers[src];
					} else {
						throw 'Expected ${variable.type}';
					}

					return variables[local].value;

				case FIELD:
					var src:Int = getInstruction();
					var dst:Int = getInstruction();
					var target:String = constants[getInstruction()];

					return registers[dst] = Reflect.getProperty(registers[src], target);

				case CALL, TRACE:
					var target:Int = getInstruction();
					var reg:Int = getInstruction();
					var len:Int = getInstruction();
					var args:Array<Dynamic> = [];
					for (_ in 0...len)
						args.push(registers[getInstruction()]);

					if (i == TRACE) {
						args.push(new Span(name, line, start, end));
					}
					return registers[reg] = Reflect.callMethod(null, registers[target], args);

				case ANONYMOUS_FUNCTION, FUNCTION:
					var fnName:String = null;
					var targetVar:Null<Int> = null;
					var depth:Int = 0;

					if (i == FUNCTION) {
						fnName = constants[getInstruction()];
						depth = getInstruction();
						targetVar = getInstruction();
					}

					var argsLen:Int = getInstruction();
					var argSlots:Array<Int> = [];
					var argTypes:Array<String> = [];

					for (_ in 0...argsLen) {
						argSlots.push(getInstruction());
						var typeIdx:Int = getInstruction();
						argTypes.push(constants[typeIdx]);
					}

					var returnTypeIdx:Int = getInstruction();
					var returnType:String = constants[returnTypeIdx];

					var bodyLen:Int = getInstruction();
					var bodyStart:Int = pc;
					pc += bodyLen;

					var frame:Array<Instruction> = [];
					for (j in 0...bodyLen)
						frame.push(instructions[bodyStart + j]);

					var capturedVars:Array<VariableSlot> = variables;

					var f:Dynamic = Reflect.makeVarArgs(function(hxArgs:Array<Dynamic>) {
						for (k in 0...argSlots.length) {
							var val:Dynamic = (k < hxArgs.length) ? hxArgs[k] : null;
							if (!isCompatible(val, argTypes[k])) {
								throw 'Type error: Argument ${k + 1} of ${fnName != null ? fnName : "Dynamic"} expected ${argTypes[k]}, got ${Type.typeof(val)}';
							}
							capturedVars[argSlots[k]] = {value: val, type: argTypes[k]};
						}

						var savedPc = pc;
						var savedInstructions = instructions;
						var savedReturning = returning;

						instructions = frame;
						pc = 0;
						returning = false;

						var last:Dynamic = null;
						while (pc < instructions.length && !returning)
							last = executeInstruction(getInstruction());

						var result = returning ? returnValue : last;

						if (returnType != "Dynamic" && returnType != "Void" && !isCompatible(result, returnType)) {
							throw 'Type error: ${fnName != null ? fnName : "Dynamic"} should return ${returnType}, got ${Type.typeof(result)}';
						}

						pc = savedPc;
						instructions = savedInstructions;
						returning = savedReturning;

						return result;
					});

					if (targetVar != null) {
						capturedVars[targetVar] = {
							value: f,
							type: "Dynamic"
						};

						if (depth == 0)
							variablesTable[fnName] = targetVar;
					}

					return f;

				case TRUE:
					return registers[getInstruction()] = true;
				case FALSE:
					return registers[getInstruction()] = false;
				case NULL:
					return registers[getInstruction()] = null;

				case VAR_DECLARATION:
					var name:String = constants[getInstruction()];
					var depth:Int = getInstruction();
					var pos:Int = getInstruction();
					var type:String = constants[getInstruction()];
					var reg:Int = getInstruction();
					variables[pos] = {
						value: (reg == -1) ? null : registers[reg],
						type: type
					};
					if (depth == 0)
						variablesTable[name] = pos;
					return null;

				case RETURN:
					var reg:Int = getInstruction();
					returnValue = (reg == -1) ? null : registers[reg];
					returning = true;
					return returnValue;

				case JUMP:
					var offset:Int = getInstruction();
					pc += offset;
					return null;

				case JUMP_IF_FALSE:
					var condReg:Int = getInstruction();
					var offset:Int = getInstruction();
					if (!registers[condReg])
						pc += offset;
					return null;

				case JUMP_IF_TRUE:
					var condReg:Int = getInstruction();
					var offset:Int = getInstruction();
					if (registers[condReg])
						pc += offset;
					return null;

				case JUMP_BACK:
					var offset:Int = getInstruction();
					pc -= offset;
					return null;

				case THROW:
					throw registers[getInstruction()];

				case OP_ADD:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] + registers[r];
				case OP_SUB:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] - registers[r];
				case OP_MULT:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] * registers[r];
				case OP_DIV:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] / registers[r];
				case OP_MOD:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] % registers[r];
				case OP_NEG:
					var src = getInstruction();
					var dst = getInstruction();
					return registers[dst] = -registers[src];

				case OP_EQUAL:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] == registers[r];
				case OP_NOT_EQUAL:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] != registers[r];
				case OP_GT:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] > registers[r];
				case OP_GTE:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] >= registers[r];
				case OP_LT:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] < registers[r];
				case OP_LTE:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] <= registers[r];

				case OP_BOOL_AND:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] && registers[r];
				case OP_BOOL_OR:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] || registers[r];
				case OP_NOT:
					var src = getInstruction();
					var dst = getInstruction();
					return registers[dst] = !registers[src];

				case OP_AND:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] & registers[r];
				case OP_OR:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] | registers[r];
				case OP_XOR:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] ^ registers[r];
				case OP_SHL:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] << registers[r];
				case OP_SHR:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] >> registers[r];
				case OP_USHR:
					var l = getInstruction();
					var r = getInstruction();
					var t = getInstruction();
					return registers[t] = registers[l] >>> registers[r];

				case _:
					return null;
			}
		} catch (m:Exception) {
			#if debug
			throw new HscriptException('$name:${line}: characters ${start}-${end}: ${m.details()}', {
				start: start,
				end: end,
				line: line,
				file: name
			});
			#else
			throw new HscriptException('$name:${line}: characters ${start}-${end}: ${m.message}', {
				start: start,
				end: end,
				line: line,
				file: name
			});
			#end
		}
	}

	private inline function getInstruction():Int {
		return instructions[pc++];
	}

	private function isCompatible(value:Dynamic, expected:String):Bool {
		if (expected == null || value == null || expected == "Dynamic" || !NeoHscript.STATIC_TYPING)
			return true;

		switch (expected) {
			case "Int":
				return Std.isOfType(value, Int);
			case "Float":
				return Std.isOfType(value, Float) || Std.isOfType(value, Int);
			case "Bool":
				return Std.isOfType(value, Bool);
			case "String":
				return Std.isOfType(value, String);
			case "Array":
				return Std.isOfType(value, Array);
			case "Void":
				return true;
			default:
				try {
					var cls = Type.resolveClass(expected);
					if (cls != null)
						return Std.isOfType(value, cls);
				} catch (e:Dynamic) {}

				if (expected.indexOf("->") >= 0 || StringTools.startsWith(expected, "Function"))
					return Reflect.isFunction(value);

				return false;
		}
	}
}
