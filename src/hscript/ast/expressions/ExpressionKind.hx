package hscript.ast.expressions;

import hscript.ast.expressions.Expression;

enum ExpressionKind {
    EInt(i:Int);
    EFloat(f:Float);
    EString(s:String);
    EIdent(i:String);

    EBinop(o:Binop, l:Expression, r:Expression);
    EUnop(o:Unop, p:Expression, post:Bool); 

    ECall(p:Expression, args:Array<Expression>);
    EField(p:Expression, f:String);
}

enum Binop {
	/**
		`+`
	**/
	OpAdd;

	/**
		`*`
	**/
	OpMult;

	/**
		`/`
	**/
	OpDiv;

	/**
		`-`
	**/
	OpSub;

	/**
		`=`
	**/
	OpAssign;

	/**
		`==`
	**/
	OpEq;

	/**
		`!=`
	**/
	OpNotEq;

	/**
		`>`
	**/
	OpGt;

	/**
		`>=`
	**/
	OpGte;

	/**
		`<`
	**/
	OpLt;

	/**
		`<=`
	**/
	OpLte;

	/**
		`&`
	**/
	OpAnd;

	/**
		`|`
	**/
	OpOr;

	/**
		`^`
	**/
	OpXor;

	/**
		`&&`
	**/
	OpBoolAnd;

	/**
		`||`
	**/
	OpBoolOr;

	/**
		`<<`
	**/
	OpShl;

	/**
		`>>`
	**/
	OpShr;

	/**
		`>>>`
	**/
	OpUShr;

	/**
		`%`
	**/
	OpMod;

	/**
		`+=` `-=` `/=` `*=` `<<=` `>>=` `>>>=` `|=` `&=` `^=` `%=`
	**/
	OpAssignOp(op:Binop);

	/**
		`...`
	**/
	OpInterval;

	/**
		`=>`
	**/
	OpArrow;

	/**
		`in`
	**/
	OpIn;

	/**
		`??`
	**/
	OpNullCoal;
}

enum Unop {
	/**
		`++`
	**/
	OpIncrement;

	/**
		`--`
	**/
	OpDecrement;

	/**
		`!`
	**/
	OpNot;

	/**
		`-`
	**/
	OpNeg;

	/**
		`~`
	**/
	OpNegBits;

	/**
		`...`
	**/
	OpSpread;
}
