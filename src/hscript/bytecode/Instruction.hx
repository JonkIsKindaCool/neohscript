package hscript.bytecode;

enum abstract Instruction(Int) from Int to Int {
	// Memory
	var LOAD_CONSTANT;
	var LOAD_LOCAL;
	var STORE_LOCAL;

	// Calls
	var CALL;
	var FUNCTION;
	var ANONYMOUS_FUNCTION;

	// Literals
	var TRUE;
	var FALSE;
	var NULL;

	// Variables
	var VAR_DECLARATION;

	// Control flow
	var RETURN;
	var JUMP;
	var JUMP_IF_FALSE;
	var JUMP_IF_TRUE;
	var JUMP_BACK;

	// Exceptions
	var THROW;

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
}
