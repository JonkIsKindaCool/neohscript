package hscript.ast.expressions;

import hscript.data.ObjectValue;
import hscript.data.FunctionArgument;
import hscript.data.Types;
import hscript.ast.expressions.Expression;

enum ExpressionKind {
	EBlock(arr:Array<Expression>);

	EInt(i:Int);
	EFloat(f:Float);
	EString(s:String);
	EIdent(i:String);
	EBool(b:Bool);
	ENull;

	EBinop(o:Binop, l:Expression, r:Expression);
	EUnop(o:Unop, p:Expression, post:Bool);

	ECall(p:Expression, args:Array<Expression>);
	EField(p:Expression, f:String);
	EArray(e:Expression, index:Expression);

	EArrayDecl(values:Array<Expression>);
	EObjectDecl(fields:Array<ObjectValue>);

	EIf(cond:Expression, then:Expression, ?elseExpr:Expression);
	ESwitch(subject:Expression, cases:Array<{values:Array<Expression>, expr:Expression}>, ?defaultExpr:Expression);

	ENew(t:Types, params:Array<Expression>);

	EFunction(name:String, args:Array<FunctionArgument>, ret:Types, body:Expression);

	EReturn(?e:Expression);
	EBreak;
	EContinue;
	EThrow(e:Expression);

	ETry(e:Expression, catches:Array<{name:String, type:Types, expr:Expression}>);

    EVar(n:String, f:Bool, ?e:Expression, ?t:Types);
	EWhile(c:Expression, b:Expression);
	EDoWhile(c:Expression, b:Expression);
}

enum Access {
	APublic;
	AInline;
	APrivate;
	AStatic;
	AOverride;
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