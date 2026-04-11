package hscript.ast.expressions;

import haxe.ds.GenericStack;
import hscript.ast.expressions.Expression;
import hscript.ast.Extras;

enum ExpressionKind {
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
	EObjectDecl(fields:Array<{field:String, expr:Expression}>);

	EIf(cond:Expression, then:Expression, ?elseExpr:Expression); 
	ESwitch(subject:Expression, cases:Array<{values:Array<Expression>, expr:Expression}>, ?defaultExpr:Expression); 

	ENew(t:ASTType, params:Array<Expression>); 

	EFunction(f:ASTFunction); 

	EReturn(?e:Expression);
	EBreak;
	EContinue;
	EThrow(e:Expression);

	ETry(e:Expression, catches:Array<{name:String, type:ASTType, expr:Expression}>);
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

@:structInit
class ASTFunction {
    public var name:Null<String>;

    public var arguments:GenericStack<FunctionArgument>;
    public var retType:ASTType;

    public var body:Expression;
}

@:structInit
class FunctionArgument {
    public var name:String;
    public var type:ASTType;
    public var optional:Bool;

    public var def:Expression;
}

@:structInit
class ASTType {
    public var name:String;
    public var generics:Array<ASTType>;
}