import haxe.Resource;
import hscript.NeoHscript;

function main() {
	// Simple test
	var script:NeoHscript = new NeoHscript();
	var result = script.execute(Resource.getString('scripts/Test1.hx'), 'Test1.hx');

	trace('Simple Script result: ' + result);

	var script:NeoHscript = new NeoHscript();
	var result = script.execute(Resource.getString('scripts/Functions.hx'), 'Functions.hx');
	result();
	trace("Simple functions passed");

	var script:NeoHscript = new NeoHscript();
	script.setGlobal('Math', Math);
	var result = script.execute(Resource.getString('scripts/Externals.hx'), 'Externals.hx');
	trace('Externals Test passed: ${result()}');

	var script:NeoHscript = new NeoHscript();
	script.setGlobal('Math', Math);
	var result = script.execute(Resource.getString('scripts/While.hx'), 'While.hx');
	trace('Whiles Test passed: ${result()}');
}
