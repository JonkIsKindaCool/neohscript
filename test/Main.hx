import haxe.Resource;
import hscript.NeoHscript;

function main() {
    var script:NeoHscript = new NeoHscript();
    trace(script.execute(Resource.getString("scripts/Test.hx"), "Test.hx")());
}