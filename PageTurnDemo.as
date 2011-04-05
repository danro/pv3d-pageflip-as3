package {
import com.paperbook.*;
import flash.display.*;
import flash.events.Event;
import flash.events.MouseEvent;

public class PageTurnDemo extends MovieClip {
	
	private var _book:Book;
	
	public function PageTurnDemo () {
		init();
	}
	
	private function init () {
		// init vars
		stage.quality = StageQuality.MEDIUM;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		
		// book
		_book = new Book();
		_book.pageWidth = 400;
		_book.pageHeight = 550;
		// book pages
		_book.addPage(FrontCover, Page1);
		_book.addPage(Page2, Page3);
		_book.addPage(Page4, Page5);
		_book.addPage(Page6, Page7);
		_book.addPage(Page8, Page9);
		_book.addPage(Page10, BackCover);
		// book init
		addChild(_book);
		_book.init();
	}
}}