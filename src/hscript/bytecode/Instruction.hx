package hscript.bytecode;

enum abstract Instruction(Int) from Int to Int {	
	var TRUE;
	var FALSE;
	var NULL;

    var LOAD_CONSTANT;
	var LOAD_LOCAL;

	var TOP_LEVEL_VAR_DECLARATION;

	var CALL;

    //Binary operators 
	// OP lReg rReg targetReg
	var OP_ADD;
	var OP_MULT;
	var OP_DIV;
	var OP_SUB;
	var OP_ASSIGN;
	var OP_EQUAL;
	var OP_NOT_EQUAL;
	var OP_GREATER;
	var OP_GREATER_EQUAL;
	var OP_LESS;
	var OP_LESS_EQUAL;
	var OP_AND;
	var OP_OR;
	var OP_XOR;
	var OP_BOOL_AND;
	var OP_BOOL_OR;
	var OP_SHIFT_LEFT;
	var OP_SHIFT_RIGHT;
	var OP_U_SHIFT_RIGHT;
	var OP_MODULO;
	var OP_ASSIGN_OP;
	var OP_INTERVAL;
	var OP_NULL_COAL;

    //Unaries
	var OP_INCREMENT;
	var OP_DECREMENT;
	var OP_NOT;
	var OP_NEG;
	var OP_NEG_BITS;
}
