package h3d.pass;

class Depth extends Default {

	var depthMapId : Int;
	public var enableSky : Bool = false;
	public var reduceSize : Int = 0;

	public function new() {
		super();
		priority = 10;
		depthMapId = hxsl.Globals.allocID("depthMap");
	}

	override function getOutputs() : Array<hxsl.Output> {
		return [PackFloat(Value("output.depth"))];
	}

	override function draw( passes ) {
		var texture = tcache.allocTarget("depthMap", ctx, ctx.engine.width >> reduceSize, ctx.engine.height >> reduceSize, true);
		ctx.engine.pushTarget(texture);
		ctx.engine.clear(enableSky ? 0 : 0xFF0000, 1);
		passes = super.draw(passes);
		ctx.engine.popTarget();
		ctx.setGlobalID(depthMapId, { texture : texture });
		return passes;
	}

}