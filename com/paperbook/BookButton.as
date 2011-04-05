package com.paperbook {
import com.paperbook.*;
import flash.display.*;
import flash.events.Event;
import flash.events.MouseEvent;

public class BookButton extends MovieClip {
	
	[Inspectable(name="Navigation Type", defaultValue="next", type="String", enumeration="next,previous,numeric")]	
	public var _navigationType:String = "next";
	
	[Inspectable(name="Numeric Page Select", defaultValue=0, type="Number")]
	public var _navPageNumber:Number = 0;
	
	public function BookButton () {
		init();
	}
	
	private function init () {
		stop();
		this.buttonMode = true;
		this.useHandCursor = true;
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		addEventListener(MouseEvent.CLICK, mouseClick);
	}
	
	private function mouseClick (event:MouseEvent) {
		// workaround for sending custom events through the virtual mouse
		var eventProxy:Function = parent["eventProxy"];
		switch (_navigationType) {
			case "next": eventProxy(new BookEvent(BookEvent.NEXT_PAGE)); break;
			case "previous": eventProxy(new BookEvent(BookEvent.PREVIOUS_PAGE)); break;
			default: eventProxy(new BookEvent(BookEvent.GOTO_PAGE, int(_navPageNumber))); break;
		}
	}
	
	private function mouseOver (event:MouseEvent) {
		this.gotoAndStop(2);
	}
	
	private function mouseOut (event:MouseEvent) {
		this.gotoAndStop(1);
	}
	
}}