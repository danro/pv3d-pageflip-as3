﻿/*
	ConstantEase 1.4 - Last updated 9/5/2010
	
	Author: Dan Rogers - dan@danro.net
	
	Description: Specialized easing utility to be used instead of TweenMan when
				 property values must constantly change (e.g. mouse movement).
	
	Usage:
	---------------------------------------------------------------------------------
	import com.tweenman.ConstantEase;

	// basic init
	var myEase = new ConstantEase(target);
	
	// extended init options
	var myEase = new ConstantEase(target, ConstantEase.ELASTIC, { easeKinetic: 0.2 });

	// set or update properties
	myEase.setProperties({ x: 200, y: 100, alpha: 0.5 });

	Ease Options:
	---------------------------------------------------------------------------------
	common:
		maxVelocity		(default: 0)	limit the maximum velocity of an ease
		sleepThreshold	(default: 0 regular, 3 elastic) number of frames to wait before sleeping
	
	regular:
		easeAmount		(default: 0.3)	amount of ease applied

 	elastic:
		easeKinetic		(default: 0.3)	amount of kinetic
		easeDamp		(default: 0.7)	amount of dampening
*/

package com.tweenman
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.utils.Dictionary;

	public class ConstantEase
	{
		// ease types
		public static var REGULAR:String = "regular";
		public static var ELASTIC:String = "elastic";

		// events
		public var onUpdate:Function;
		public var onComplete:Function;
	
		// properties
		private var targ:*;
		private var listenTarget:Shape;
		private var easeList:Dictionary = new Dictionary;
		private var active:Boolean;
		private var easeClass:Class;
		private var easeOptions:Object;

		// constructor
		public function ConstantEase ($targ:*, $type:String=null, $options:Object=null)
		{
			targ = $targ;
			switch($type)
			{
				case ELASTIC: 
					easeClass = ElasticEase; break;
				case REGULAR: 
				default: 
					easeClass = RegularEase; break;
			}
			setOptions($options);
		}

		public function setOptions ($options:Object):void
		{
			easeOptions = $options;
			for each (var ease in easeList)
			{
				ease.setProps(easeOptions);
			}
		}

		public function setProperties ($newProps:Object):void
		{
			var propsChanged:Boolean = false;
			for (var p:String in $newProps)
			{
				if (easeList[p] == null)
				{
					easeList[p] = new easeClass(targ, p, $newProps[p], easeOptions);
					propsChanged = true;
				}
				else if (easeList[p].finish != $newProps[p] || targ[p] != $newProps[p])
				{
					easeList[p].finish = $newProps[p];
					easeList[p].reset();
					propsChanged = true;
				}
			}
			if (propsChanged) enable();
		}
	
		public function getVelocity ($prop:String):Number
		{
			return easeList[$prop].velocity;
		}
	
		public function isActive ():Boolean
		{
			return active;
		}
	
		public function enable ():void
		{
			if (!active)
			{
				if (listenTarget == null) listenTarget = new Shape;
				listenTarget.addEventListener(Event.ENTER_FRAME, update);
				active = true;
			}
		}
	
		public function disable ():void
		{
			if (listenTarget != null)
			{
				listenTarget.removeEventListener(Event.ENTER_FRAME, update);
				active = false;	
			}
		}
	
		private function update ($e:Event=null):void
		{
			var allSleeping:Boolean = true;
			
			for each (var ease in easeList)
			{
				if (!ease.sleeping)
				{
					ease.update();
					allSleeping = false;
				}
			}
			if (onUpdate != null) onUpdate();
			if (allSleeping)
			{
				disable();
				if (onComplete != null) onComplete();
			}
		}
	}
}

internal class RegularEase {

	// options
	public var sleepThreshold:int;
	public var maxVelocity:Number;
	public var easeAmount:Number;
	public var easeKinetic:Number;
	public var easeDamp:Number;
	
	// properties
	public var targ:*;
	public var prop:String;
	public var finish:Number;
	public var sleepCount:int;
	public var velocity:Number;
	public var lastValue:Number;
	public var sleeping:Boolean;

	public function RegularEase ($targ:*, $prop:String, $finish:Number, $options:Object)
	{
		targ = $targ;
		prop = $prop;
		finish = $finish;
		construct();
		setProps($options);
		reset();
	}

	public function construct ():void
	{
		sleepThreshold = 0;
		maxVelocity = 0;
		easeAmount = 0.3;
	}

	public function setProps ($props:Object):void
	{
		for (var i:String in $props) this[i] = $props[i];
	}

	public function reset ():void
	{
		sleepCount = 0;
		sleeping = false;
	}

	public function getNext ():Number
	{
		var diff:Number = finish - targ[prop];
		velocity = diff * easeAmount;
		if (maxVelocity > 0)
		{
			if (velocity < -maxVelocity) velocity = -maxVelocity;
			if (velocity > maxVelocity) velocity = maxVelocity;
		}
		return targ[prop] + velocity;
	}

	public function update ():void
	{
		targ[prop] = getNext();
		if (lastValue == targ[prop]) sleepCount++;
		if (sleepCount > sleepThreshold)
		{
			targ[prop] = finish;
			sleeping = true;
		}
		lastValue = targ[prop];
	}
}

internal class ElasticEase extends RegularEase {

	public function ElasticEase ($targ:*, $prop:String, $finish:Number, $options:Object)
	{
		super($targ, $prop, $finish, $options);
	}

	public override function construct ():void
	{
		sleepThreshold = 3;
		maxVelocity = 0;
		easeAmount = 0.3;
		easeKinetic = 0.3;
		easeDamp = 0.7;
		velocity = 0;
	}

	public override function getNext ():Number
	{
		velocity += (finish - targ[prop]) * easeKinetic;
		velocity *= easeDamp;
		if (maxVelocity > 0)
		{
			if (velocity < -maxVelocity) velocity = -maxVelocity;
			if (velocity > maxVelocity) velocity = maxVelocity;
		}
		return targ[prop] + velocity;
	}
}
