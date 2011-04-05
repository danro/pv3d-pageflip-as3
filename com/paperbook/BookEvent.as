package com.paperbook {
import com.paperbook.*;
import flash.events.Event;

public class BookEvent extends Event {
	
	public static const NEXT_PAGE:String = "nextPage";
	public static const PREVIOUS_PAGE:String = "previousPage";
	public static const GOTO_PAGE:String = "goToPage";
	
	public var pageNumber:int;
	
	public function BookEvent (type:String, n:int=0) {
		super(type);
		pageNumber = n;
	}
}}