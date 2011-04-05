package com.paperbook {
import com.paperbook.*;
import flash.display.*;
import flash.events.*;
import flash.filters.DropShadowFilter;
import fl.motion.Color;
import flash.utils.Timer;
import flash.events.TimerEvent;

import com.tweenman.TweenMan;
import com.tweenman.ConstantEase;
import fl.motion.easing.*;

import org.papervision3d.Papervision3D;
import org.papervision3d.events.InteractiveScene3DEvent;
import org.papervision3d.scenes.InteractiveScene3D;
import org.papervision3d.cameras.Camera3D;
import org.papervision3d.objects.DisplayObject3D;
import org.papervision3d.materials.*;
import org.papervision3d.utils.*;
import org.papervision3d.objects.Plane;
import org.papervision3d.utils.virtualmouse.VirtualMouse;
import org.papervision3d.utils.virtualmouse.IVirtualMouseEvent;

public class Book extends MovieClip {
	
	// public properties
	public var pageWidth:Number = 300;
	public var pageHeight:Number = 400;
	
	// constants
	public static const PAGE_CHANGE:String = "pageChange";
	public static const SIDE_RIGHT:String = "sideRight";
	public static const SIDE_LEFT:String = "sideLeft";
	public static const DEFAULT_FOCUS:Number = 800;
	
	// papervision properties
	private var _container		:Sprite;
	private var _scene			:InteractiveScene3D;
	private var _camera			:Camera3D;
	private var _ism			:InteractiveSceneManager;
	private var _vmouse			:VirtualMouse;
	
	// private properties
	private var _pages:Array;
	private var _index:int = 0;
	private var _freeLook:Boolean = true;
	private var _lastCamX:Number;
	private var _lastCamY:Number;
	private var _button1:MovieClip;
	private var _button2:MovieClip;
	private var _pageFlipFreeLook:Boolean;
	private var _pageFlipMode:Boolean;
	private var _pageFlipIndex:int;
	private var _pageFlipTimer:Object = {};
	private var _cameraEase:ConstantEase;
	
	public function Book () {
		// init vars
		Papervision3D.VERBOSE = false;
		_pages = [];
		this.alpha = 0;
	}
	
	public function addPage (side1:*, side2:*, curved:Boolean=true) {
		var page:BookPage = new BookPage(side1, side2, curved, _pages.length);
		page.addEventListener(BookPage.MOTION_FINISHED, pageStopped);
		page.addEventListener(BookEvent.NEXT_PAGE, goNext);
		page.addEventListener(BookEvent.PREVIOUS_PAGE, goBack);
		page.addEventListener(BookEvent.GOTO_PAGE, goToPage);
		page.rotationChanged = pageRotationChanged;
		addChild(page);
		_pages.push(page);
	}
	
	public function init () {
		// camera button 1 -----------
		_button1 = new BasicButton();
		addChild(_button1);
		_button1._label.text = "Fixed Camera";
		_button1.x = -_button1.width;
		_button1.buttonMode = true;
		_button1.mouseChildren = false;
		_button1.addEventListener(MouseEvent.CLICK, cameraMode1);
		
		// camera button 2 -----------
		_button2 = new BasicButton();
		addChild(_button2);
		_button2._label.text = "Free Camera";
		_button2.x = _button2.width;
		_button2.y = pageHeight/2 + _button2.height;
		_button2.buttonMode = true;
		_button2.mouseChildren = false;
		_button2.addEventListener(MouseEvent.CLICK, cameraMode2);
		
		// fade in
		TweenMan.addTween(this, { alpha: 1, frames: 20, delay: 5 });

		// add container
		_container = new InteractiveSprite();
		_container.name = "mainCont";
		addChild(_container);
		
		// interactive scene manager
		_scene = new InteractiveScene3D(_container);
		_ism = _scene.interactiveSceneManager;
		_ism.setInteractivityDefaults();
		_vmouse = _ism.virtualMouse;
		InteractiveSceneManager.SHOW_DRAWN_FACES = true;
		InteractiveSceneManager.DEFAULT_SPRITE_ALPHA = 0;
		
		// camera
		_camera = new Camera3D();
		_camera.zoom = 2.25;
		_camera.focus = DEFAULT_FOCUS;
		_cameraEase = new ConstantEase(_camera, ConstantEase.REGULAR, { easeAmount: 0.5 });
		
		// events
		stage.addEventListener(Event.RESIZE, stageResize);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
		stage.addEventListener(Event.ENTER_FRAME, enterFrame);
		add3DPage(SIDE_RIGHT, currentIndex);
		stageResize();
		
		cameraMode1();
	}

	private function keyUpHandler(event:KeyboardEvent):void {
		if (_pageFlipMode) return;
		var KEY_RIGHT:Number = 39;
		var KEY_LEFT:Number = 37;
		switch (event.keyCode) {
		case KEY_RIGHT: goNext(); break;
		case KEY_LEFT: goBack(); break;
		}
	}
	
	private function mouseWheel (event:MouseEvent) {
		//_camera.focus += event.delta*10;
	}
	
	private function stageResize (event:Event=null) {
		var halfWidth = stage.stageWidth*.5;
		var halfHeight = stage.stageHeight*.5;
		this.x = halfWidth;
		this.y = halfHeight;
		
		_button1.y = halfHeight - 20;
		_button2.y = halfHeight - 20;
		
		enterFrame();
	}
	
	private function pageRotationChanged (index:int, pageRotation:Number, forward:Boolean) {
		var nextPage:BookPage = _pages[index + 1];
		var prevPage:BookPage = _pages[index - 1];
		var bright:Number;
		if (prevPage != null) {
			bright = pageRotation > 90 ? -(pageRotation-90)/90 : 0;
			prevPage.setBrightness(bright);
		}
		if (nextPage != null) {
			bright = pageRotation < 90 ? (pageRotation-90)/90 : 0;
			nextPage.setBrightness(bright);
		}
	}
	
	private function enterFrame (event:Event=null) {
		// adjust free look
		var percentX = (stage.mouseX - stage.stageWidth/2) / (stage.stageWidth);			
		var percentY = (stage.mouseY - stage.stageHeight/2) / (stage.stageHeight);
		_lastCamX = percentX * 1000;
		_lastCamY = -percentY * 2000;
		if (_freeLook && !_pageFlipMode) {
			_cameraEase.setProperties({ x: _lastCamX, y: _lastCamY, focus: DEFAULT_FOCUS });
		}
		// render the scene
		_container.cacheAsBitmap = true;
		_scene.renderCamera( _camera );
		_container.cacheAsBitmap = false;
	}
	
	public function cameraMode1 (event:MouseEvent=null, ease:Function=null) {
		if (ease == null) ease = Back.easeOut;
		_cameraEase.disable();
		_freeLook = false;
		TweenMan.addTween(_camera, { x: 0, y: 0, focus: DEFAULT_FOCUS, frames: 10, ease: ease });
		_button1.alpha = .4;
		_button2.alpha = 1;
	}
	
	public function cameraMode2 (event:MouseEvent=null, ease:Function=null) {
		if (_freeLook != true) {
			_freeLook = true;
			_button1.alpha = 1;
			_button2.alpha = .4;
		}
	}
	
	public function startPageFlip (startIndex:int=0) {
		disableMouseEvents();
		_pageFlipFreeLook = _freeLook;
		_freeLook = false;
		_pageFlipMode = true;
		_pageFlipIndex = startIndex;
		TweenMan.addTween(_camera, { x: 0, y: -1200, focus: 200, frames: 20 });
		TweenMan.addTween(_pageFlipTimer, { frames: 2, onComplete: pageFlipHandler });
	}

	private function endPageFlip () {
		TweenMan.removeTweens(_pageFlipTimer);
		_pageFlipMode = false;
		if (_pageFlipFreeLook) {
			cameraMode2();
		} else {
			cameraMode1(null, Quintic.easeInOut);
		}
		enableMouseEvents();
	}

	public function pageFlipHandler():void {
		TweenMan.addTween(_pageFlipTimer, { frames: 5, onComplete: pageFlipHandler });
		if (_pageFlipIndex == currentIndex) {
			endPageFlip();
		} else if (_pageFlipIndex > currentIndex) {
			goNext();
		} else if (_pageFlipIndex < currentIndex) {
			goBack();
		}
	}
	
	public function goToPage (event:BookEvent=null) {	
		if (event.pageNumber == currentIndex + 1) {
			goNext();
		} else if (event.pageNumber == currentIndex - 1) {
			goBack();
		} else if (event.pageNumber != currentIndex) {
			startPageFlip(event.pageNumber);
		}
	}
	
	public function goNext (event:BookEvent=null) {
		if (currentIndex < _pages.length) {
			disableMouseEvents();
			add3DPage(SIDE_RIGHT, currentIndex);
			_pages[currentIndex].goForward();
			add3DPage(SIDE_RIGHT, ++currentIndex);
		}
	}
	
	public function goBack (event:BookEvent=null) {
		if (currentIndex > 0) {
			disableMouseEvents();
			currentIndex--;
			add3DPage(SIDE_LEFT, currentIndex-1);
			add3DPage(SIDE_LEFT, currentIndex);
			_pages[currentIndex].goReverse();
		}
	}
	
	private function add3DPage (side:String, index:int) {
		var page:BookPage = _pages[index];
		if (page != null) {
			var pageAdded:Boolean = page.addToScene(_scene);
			if (pageAdded) {
				if (side == SIDE_LEFT) {
					page.rotatePlanes(180);
				} else {
					page.rotatePlanes(0);
				}
			}
		}
	}
	
	private function remove3DPage (index:int) {
		var page:BookPage = _pages[index];
		if (page != null) {
			page.removeFromScene(_scene);
		}
	}
	
	private function pageStopped (event:Event) {
		var page:BookPage = event.target as BookPage;
		
		if (page.pageRotation == 180) {
			remove3DPage(page.index-1);
		} else {
			remove3DPage(page.index+1);
		}
		enableMouseEvents();	
	}
	
	private function set currentIndex (index:int) {
		if (index < 0) {
			 _index = 0;
		} else if (index > _pages.length) {
			_index = _pages.length;
		} else {
			_index = index;
		}
	}
	
	private function get currentIndex ():int {
		return _index;
	}
	
	private function disableMouseEvents () {
		this.mouseEnabled = false;
		this.mouseChildren = false;
	}
	
	private function enableMouseEvents () {
		this.mouseEnabled = true;
		this.mouseChildren = true;
	}
}}