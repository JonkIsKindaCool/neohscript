package hscript.bytecode;

enum abstract Byte(UInt) from UInt to UInt {
	var GET_CONSTANT;
	var GET_VARIABLE;

	var TRUE;
	var FALSE;
	var NULL;

	var ARRAY;
	var OBJECT;

	var TRACE;
	var CALL;
	var CALL_FIELD;
	var FIELD;
	var INDEX;

	var RETURN;
	var BREAK;
	var CONTINUE;

	var ANONYMOUS_FUNCTION;
	var FUNCTION;
	var DEFINE_VARIABLE;
	var SET_VARIABLE;
	var SET_FIELD;

	var PUSH_SCOPE;
	var POP_SCOPE;

	var JUMP;
	var JUMP_IF_FALSE;
	var JUMP_IF_TRUE;
	var JUMP_BACK;

	// Arithmetic  (lhs rhs dst)
	var OP_ADD;
	var OP_SUB;
	var OP_MULT;
	var OP_DIV;
	var OP_MOD;

	// Unary arithmetic  (src dst)
	var OP_NEG;

	// Comparison  (lhs rhs dst)
	var OP_EQUAL;
	var OP_NOT_EQUAL;
	var OP_GT;
	var OP_GTE;
	var OP_LT;
	var OP_LTE;

	// Boolean  (lhs rhs dst)
	var OP_BOOL_AND;
	var OP_BOOL_OR;

	// Unary boolean  (src dst)
	var OP_NOT;

	// Bitwise  (lhs rhs dst)
	var OP_AND;
	var OP_OR;
	var OP_XOR;
	var OP_SHL;
	var OP_SHR;
	var OP_USHR;

	// Others
	var OP_INTERVAL;
}
