package com.paperbook {
import com.paperbook.*;
import flash.display.*;
import flash.filters.DropShadowFilter;
import flash.events.Event;
import flash.events.MouseEvent;

import fl.motion.Color;

import org.papervision3d.materials.*;
import org.papervision3d.scenes.*;

public class BookPage extends Sprite {
	
	// events
	public static const MOTION_FINISHED:String = "motionFinished";
	public static const ROTATION_CHANGED:String = "rotationChanged";
	
	// public properties
	public var sprite1:Sprite;
	public var sprite2:Sprite;
	public var material1:InteractiveMovieMaterial;
	public var material2:InteractiveMovieMaterial;
	public var plane1:CurlingPlane;
	public var plane2:CurlingPlane;
	public var speed:int = 14;
	public var pageRotation:int = 0;
	public var index:int;
	public var rotationChanged:Function;
	
	// private properties
	private var _clip1:Class;
	private var _clip2:Class;
	private var _color:Color;
	private var _forward:Boolean = true;
	
	public function BookPage (side1:*, side2:*, curved:Boolean, index:int) {			
		// init vars
		_clip1 = side1;
		_clip2 = side2;
		_color = new Color();
		this.index = index;
		
		// page 1
		sprite1 = new _clip1();
		
		// page 2
		sprite2 = new Sprite();
		var child = sprite2.addChild(new _clip2());
		child.name = "child";
		child.scaleX = -1;
		child.x = sprite2.width;
		
		// material 1
		material1 = new InteractiveMovieMaterial(sprite1);
		material1.smooth = true;
		material1.animated = false;
		material1.invisible = true;
		material1.updateBitmap();
		
		// material 2
		material2 = new InteractiveMovieMaterial(sprite2);
		material2.smooth = true;
		material2.animated = false;
		material2.opposite = true;
		material2.invisible = true;
		material2.updateBitmap();
		
		// create planes
		plane1 = new CurlingPlane(material1);
		plane2 = new CurlingPlane(material2);
	}
	
	public function dispatchBookEvent (event:BookEvent) {
		dispatchEvent(event);
	}
	
	public function addToScene (scene:InteractiveScene3D):Boolean {
		// add planes to scene if they do not already exist
		if (Boolean(scene.getChildByName(plane1.name))) {
			return false;
		} else {
			setMaterialMode(true);
			scene.addChild(plane1);
			scene.addChild(plane2);
			
			// TODO - figure out which sprite causes the hand cursor
			//plane1.container.useHandCursor = false;
			//plane2.container.useHandCursor = false;
			
			// workaround for sending custom events through the virtual mouse
			var mc1 = material1.movie;
			mc1.eventProxy = dispatchBookEvent;
			material1.updateBitmap();
			var mc2 = material2.movie;
			mc2 = mc2.getChildByName("child");
			mc2.eventProxy = dispatchBookEvent;
			material2.updateBitmap();
						
			return true;
		}
	}
	
	public function removeFromScene (scene:InteractiveScene3D) {
		scene.removeChild(plane1);
		scene.removeChild(plane2);
		setMaterialMode(false, true);
	}
	
	private function setMaterialMode (animated:Boolean, invisible:Boolean=false) {
		material1.animated = animated;
		material1.invisible = invisible;
		material1.updateBitmap();
		material2.animated = animated;
		material2.invisible = invisible;
		material2.updateBitmap();
	}
	
	public function rotatePlanes (newRotation:Number) {
		if (newRotation != pageRotation) {
			plane1.rotate(newRotation);
			plane2.rotate(newRotation);
			pageRotation = int(plane1.currentRotation);
			rotationChanged(index, pageRotation, _forward);
		}
	}
	
	public function goForward () {
		_forward = true;
		enableEnterFrame();
	}
	
	public function goReverse () {
		_forward = false;
		enableEnterFrame();
	}
	
	private function enableEnterFrame () {
		setMaterialMode(false);
		stage.addEventListener(Event.ENTER_FRAME, enterFrame);
		enterFrame();
	}
	
	private function get nextRotation ():int {
		return _forward ? pageRotation + speed : pageRotation - speed;
	}
	
	public function setBrightness (bright:Number) {
		if (_color.brightness != bright && plane1.container != null) {
			_color.brightness = Math.min(0, bright+.2);
			plane1.container.transform.colorTransform = _color;
			plane2.container.transform.colorTransform = _color;
		}
	}
	
	private function enterFrame (event:Event=null):void {
		// rotate the plane			
		rotatePlanes(nextRotation);

		// bounds tweaking
		if (_forward) {
			if (pageRotation < 30) {
				plane1.setDirection(true);
				plane2.setDirection(true);
			}
		} else {
			if (pageRotation > 150) {
				plane1.setDirection(false);
				plane2.setDirection(false);
			}
		}
		if ((_forward && pageRotation == 180) || (!_forward && pageRotation == 0)) {
			motionFinished();
		}
	}
	
	private function motionFinished () {
		stage.removeEventListener(Event.ENTER_FRAME, enterFrame);
		setMaterialMode(true);
		dispatchEvent(new Event(MOTION_FINISHED));
	}
}}