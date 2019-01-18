package h2d;

class Layers extends Object {

	// the per-layer insert position
	var layersIndexes : Array<Int>;
	var layerCount : Int;

	public function new(?parent) {
		super(parent);
		layersIndexes = [];
		layerCount = 0;
	}

	override function addChild(s) {
		addChildAt(s, 0);
	}

	public inline function add(s, layer) {
		return addChildAt(s, layer);
	}

	override function addChildAt( s : Object, layer : Int ) {
		if( s.parent == this ) {
			var old = s.allocated;
			s.allocated = false;
			removeChild(s);
			s.allocated = old;
		}
		// new layer
		while( layer >= layerCount )
			layersIndexes[layerCount++] = children.length;
		super.addChildAt(s,layersIndexes[layer]);
		for( i in layer...layerCount )
			layersIndexes[i]++;
	}

	override function removeChild( s : Object ) {
		for( i in 0...children.length ) {
			if( children[i] == s ) {
				children.splice(i, 1);
				if( s.allocated ) s.onRemove();
				s.parent = null;
				s.posChanged = true;
				if( s.parentContainer != null ) s.setParentContainer(null);
				var k = layerCount - 1;
				while( k >= 0 && layersIndexes[k] > i ) {
					layersIndexes[k]--;
					k--;
				}
				onContentChanged();
				break;
			}
		}
	}

	public function under( s : Object ) {
		for( i in 0...children.length )
			if( children[i] == s ) {
				var pos = 0;
				for( l in layersIndexes )
					if( l > i )
						break;
					else
						pos = l;
				var p = i;
				while( p > pos ) {
					children[p] = children[p - 1];
					p--;
				}
				children[pos] = s;
				break;
			}
	}

	public function over( s : Object ) {
		for( i in 0...children.length )
			if( children[i] == s ) {
				for( l in layersIndexes )
					if( l > i ) {
						for( p in i...l-1 )
							children[p] = children[p + 1];
						children[l - 1] = s;
						break;
					}
				break;
			}
	}

	public function getLayer( layer : Int ) : Iterator<Object> {
		var a;
		if( layer >= layerCount )
			a = [];
		else {
			var start = layer == 0 ? 0 : layersIndexes[layer - 1];
			var max = layersIndexes[layer];
			a = children.slice(start, max);
		}
		return new hxd.impl.ArrayIterator(a);
	}

	function drawLayer( ctx : RenderContext, layer : Int ) {
		if( layer >= layerCount )
			return;
		var old = ctx.globalAlpha;
		ctx.globalAlpha *= alpha;
		var start = layer == 0 ? 0 : layersIndexes[layer - 1];
		var max = layersIndexes[layer];
		if( ctx.front2back ) {
			for( i in start...max ) children[max - 1 - i].drawRec(ctx);
		} else {
			for( i in start...max ) children[i].drawRec(ctx);
		}
		ctx.globalAlpha = old;
	}

	public function ysort( layer : Int ) {
		if( layer >= layerCount ) return;
		var start = layer == 0 ? 0 : layersIndexes[layer - 1];
		var max = layersIndexes[layer];
		if( start == max )
			return;
		var pos = start;
		var ymax = children[pos++].y;
		while( pos < max ) {
			var c = children[pos];
			if( c.y < ymax ) {
				var p = pos - 1;
				while( p >= start ) {
					var c2 = children[p];
					if( c.y >= c2.y ) break;
					children[p + 1] = c2;
					p--;
				}
				children[p + 1] = c;
			} else
				ymax = c.y;
			pos++;
		}
	}

	//swap out objects of one layer with another layer, useful when wanting to draw objects of lower layer above the current higher layer. 
	public function swap( layer1 : Int, layer2 : Int ) {
		if( layer1 == layer2 || layer1 >= layerCount || layer2 >= layerCount ) return;		
		var higherlayer, lowerlayer; 
		if( layer1 > layer2){ 
			higherlayer = layer1; 
			lowerlayer = layer2;
		} else { 
			higherlayer = layer2; 
			lowerlayer = layer1;
		}		
		var diffLen = 0;
		for(i in 0...2){
			var layer = higherlayer - (higherlayer - lowerlayer) * i
		    	var Start = layer == 0 ? 0 : layersIndexes[layer - 1];
			var Len = layersIndexes[layer] - Start;
			var a = children.splice(Start, Len);			
			diffLen += (Len * hxd.Math.pow(-1, i));
			var k = Len;
			while(k > 0){
				if(i == 0 && lowerlayer - 1 < 0) children.insert(0, a[k-1]);
				else children.insert(layersIndexes[lowerlayer - 1 + (higherlayer - lowerlayer)*i] + (diffLen * i), a[k-1]);
		    		k--;
			}
		}		
		for(i in lowerlayer...higherlayer)){
		    layersIndexes[i] += diffLen;
		}
	}
}
