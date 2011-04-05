/*
	CurlingPlane.as
	Lee Felarca
	http://www.zeropointnine.com/blog
	v0.8.1 - 4-22-2007
	
	Mimics the curling of a sheet of paper, as if a page is being turned in a book.
	
	Source code licensed under a Creative Commons Attribution 3.0 License.
	http://creativecommons.org/licenses/by/3.0/
	Some Rights Reserved. Improvements made to this class are encouraged.
	
	HISTORY:
	
		v0.8.1	Removed sharedPresets() method, as it turned out to be little use.
				Added tesselation parameter to constructor.
				
		v0.8.0 	First public release	
*/

package com.paperbook {
import com.paperbook.*;
import org.papervision3d.core.*;
import org.papervision3d.core.proto.*;
import org.papervision3d.core.geom.*;
import org.papervision3d.materials.BitmapMaterial;
import flash.display.BitmapData;


public class CurlingPlane extends Mesh3D {
	
	// public properties
	public var currentRotation:int = 0;
	public var direction:Boolean = true;
	
	// constants
	private static const MAX_ROTATION:Number = 180;
	
	// private properties
	private var stripsU:Array = new Array();
	private var vStripWidths:Array = new Array();
	private var origVerts:Array = new Array();
	private var vertices:Array;
	private const DEGREE:Number = Math.PI / 180;
	private var boundary1:Number;
	private var boundary2:Number;
	private var boundary1Mod:Number;
	private var boundary2Mod:Number;
	private var segmentsW:int = 5;
	private var segmentsH:int = 5;

	// hard-coded magic numbers (!) :P 
	private var BOUNDS_FWD:Array = [
		55, 	// 55
		110, 	// 130
		1.4, 	// 1.35
		0.3 	// 0.6
	];
	// magic numbers for reverse direction
	private var BOUNDS_REV:Array = [
		-55,
		110,
		1.35,
		0.6
	];

	/*
	 *	PARAMETERS:
	 *		
	 *		material				The MaterialObject3D to be mapped to the plane.
	 *		reverseDirection		Reverse the direction of the animation.
	 */
	public function CurlingPlane(material:MaterialObject3D) {
		super( material, new Array(), new Array(), null, null );
		
		// spaces segmentsW in a logarithmic progression
		for (var i:int = 0; i <= segmentsW; i++)
			stripsU[i] = Math.log(i+1) / Math.log(segmentsW+1);

		var bmp:BitmapData = this.material.bitmap;
	 	vertices = this.geometry.vertices;

		var width:Number = bmp.width;
		var height:Number = bmp.height;			

		var faces:Array = this.geometry.faces;

		var gridX    :Number = segmentsW;
		var gridY    :Number = segmentsH;
		var gridX1   :Number = gridX + 1;
		var gridY1   :Number = gridY + 1;	

		var iW       :Number = width / gridX;
		var iH       :Number = height / gridY;

		// Vertices
		for( var ix:int = 0; ix < gridX1; ix++ )
		{
			for( var iy:int = 0; iy < gridY1; iy++ )
			{
				var idx:Number = Math.floor( ix / (segmentsH+1) );
				var x:Number = stripsU[idx] * width;
				var y :Number = iy * iH - (height/2);	
				vertices.push( new Vertex3D( x, y, 0 ) );
			}
		}

		// Faces
		var uvA :NumberUV;
		var uvC :NumberUV;
		var uvB :NumberUV;

		for(  ix = 0; ix < gridX; ix++ )
		{
			for(  iy= 0; iy < gridY; iy++ )
			{
				// Triangle A
				var a:Vertex3D = vertices[ ix     * gridY1 + iy     ];
				var c:Vertex3D = vertices[ ix     * gridY1 + (iy+1) ];
				var b:Vertex3D = vertices[ (ix+1) * gridY1 + iy     ];

				uvA =  new NumberUV( stripsU[ix],  iy     / gridY );
				uvC =  new NumberUV( stripsU[ix],  (iy+1) / gridY );
				uvB =  new NumberUV( stripsU[ix+1], iy    / gridY );

				faces.push( new Face3D( [ a, b, c ], null, [ uvA, uvB, uvC ] ) );

				// Triangle B
				a = vertices[ (ix+1) * gridY1 + (iy+1) ];
				c = vertices[ (ix+1) * gridY1 + iy     ];
				b = vertices[ ix     * gridY1 + (iy+1) ];

				uvA =  new NumberUV( stripsU[ix+1], (iy+1) / gridY );
				uvC =  new NumberUV( stripsU[ix+1], iy     / gridY );
				uvB =  new NumberUV( stripsU[ix],   (iy+1) / gridY );

				faces.push( new Face3D( [ a, b, c ], null, [ uvA, uvB, uvC ] ) );
			}
		}
		
		// store the (unrotated) verts
		for (var l:int = 0; l < vertices.length; l++) {
			origVerts[l] = new Vertex3D();
			origVerts[l].x = vertices[l].x;
			origVerts[l].y = vertices[l].y;
			origVerts[l].z = vertices[l].z;
		}

		// calc rectangle widths			
		vStripWidths = new Array();
		for (var m:int = 0; m < segmentsW; m++) {
			vStripWidths[m] = stripsU[m+1] * width - stripsU[m] * width;
		}

		this.geometry.ready = true;
		
		// set forward bounds by default
		setDirection(true);
	}
	
	public function setDirection (forward:Boolean=true) {
		var boundsSet:Array = forward ? BOUNDS_FWD : BOUNDS_REV;
		direction = forward;
		boundary1 = boundsSet[0];
		boundary2 = boundsSet[1];
		boundary1Mod = boundsSet[2];
		boundary2Mod = boundsSet[3];
		rotate(currentRotation);
	}
	
	public function rotate (degree:Number):void {
		if (degree<0) degree=0;
		if (degree>MAX_ROTATION) degree=MAX_ROTATION;
		currentRotation = int(degree);
		applyVerts( calcVerts(currentRotation) );
	}		

	private function calcVerts( degRot:int ) : Array {
		if (degRot<0) degRot=0;
		if (degRot>MAX_ROTATION) degRot=MAX_ROTATION;

		var myVerts:Array = new Array();						
		var vStripRots:Array = new Array();
			var r:Number = -degRot * DEGREE;				
		var rMod:Number;
					
		// Calculate rotation amounts for each rectangle and store in vStripRots

		// [A] Applies to all degrees
		rMod = boundary1Mod;
		
		// [B] Applies to all degrees > boundary1
		if (degRot > boundary1) {
			var a:Number = degRot - boundary1; // range: 0 to MAX_ROTATION - B1
			a = a / (boundary2 - boundary1) * boundary2Mod; // range: 0 to B2MOD
			rMod -= a;	// range: B1MOD to B1MOD-B2MOD
		}

		// Recursively multiply vStripRots elements by rMod
		for (var i:int=0; i < segmentsW; i++) {
			vStripRots[i] = r;
			r *= rMod;
		}

		// [C] Applies to degrees > boundary2. 
		// 	   Grow vStripRots proportionally to MAX_ROT. (Note the 'additive' nature of these 3 steps).
		if (degRot >= boundary2) {
			for (var j:int=0; j < vStripRots.length; j++) {
				var diff:Number = MAX_ROTATION*DEGREE - Math.abs(vStripRots[j]);
				var rotMult:Number = degRot - boundary2; // range: 0 to 30
				rotMult = rotMult / (MAX_ROTATION - boundary2); // range: 0 to 1
				vStripRots[j] -= diff * rotMult; // range: __ to MAX_ROTATION
			}
		}
		
		// [2] Create myVerts[]
		for (var k:int=0; k <  vertices.length; k++) {	
			var idx:Number = Math.floor( k / (segmentsH+1) ) - 1;
			if (idx>=0) {
				myVerts[k] = new Vertex3D( vStripWidths[idx], origVerts[k].y, origVerts[k].z );
			} else {
				myVerts[k] = new Vertex3D( origVerts[k].x,    origVerts[k].y, origVerts[k].z );				
			}
		}

		// [3] Apply rotation to myVerts[]			
		for (var l:int = segmentsH+1; l < myVerts.length; l++) {
			var idx2:Number = Math.floor( l / (segmentsH+1) ) - 1;
			myVerts[l] = rotateVertexY( myVerts[l], vStripRots[idx2] )
		}

		// [4] 'connect' the rectangles
		for (var m:int = (segmentsH+1) * 2; m < myVerts.length; m++) { // (first 2 edges are fine)
			myVerts[m].x += myVerts[ m - (segmentsH+1) ].x;
			myVerts[m].z += myVerts[ m - (segmentsH+1) ].z; // (y stays constant)
		}
		
		return myVerts;
	}


	private function applyVerts( v:Array ) : void {
		for (var i:int = 0; i < vertices.length; i++) {
			vertices[i].x = v[i].x;
			vertices[i].y = v[i].y;
			vertices[i].z = v[i].z;  
		}
	}
			
	private function rotateVertexY( p:Vertex3D, angleY:Number ):Vertex3D {
		var x:Number = Math.cos(angleY) * p.x - Math.sin(angleY) * p.z;
		var z:Number = Math.cos(angleY) * p.z + Math.sin(angleY) * p.x;
		var y:Number = p.y;
		return new Vertex3D(x, y, z);
	}
}}