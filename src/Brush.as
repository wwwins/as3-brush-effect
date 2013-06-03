package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author flashisobar
	 */
	public class Brush extends Sprite
	{
		[Embed(source = "../assets/bg.jpg")] private const BG:Class;
		
		public var mousePressed:Boolean = false;
		public var pictureBitmap:Bitmap;
		private var tailLine:TailLine;
		private var mask_mc:Mask;
		
		public static var w:Number;
		public static var h:Number;
		
		public function Brush():void
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			w = Constants.CanvasWidth;
			h = Constants.CanvasHeight;
			
			tailLine = new TailLine();
			// mask
			mask_mc = new Mask();
			mask_mc.visible = false;
			addChild(mask_mc);
			// output layer
			pictureBitmap = new Bitmap();
			// without transparent
			//pictureBitmap.bitmapData = new BitmapData(w, h, false, 0xFFC52D27);
			// with transparent
			pictureBitmap.bitmapData = new BitmapData(w, h, true, 0x00C52D27);
			//pictureBitmap.alpha = .85;
			pictureBitmap.mask = mask_mc;
			// mouse hitarea
			this.addChild(new ButtonSprite());
			// background
			var bg:Bitmap = new BG();
			bg.x = -Constants.CanvasX;
			bg.y = -Constants.CanvasY;
			this.addChild(bg);
			// final output
			this.addChild(pictureBitmap);
			// brush layer
			this.addChild(tailLine);
			
			addEventListener(Event.ENTER_FRAME, loop);
		}
		
		private function loop(evt:Event):void
		{
			if (mousePressed)
			{
				pictureBitmap.bitmapData.draw(tailLine.bitmapData, null, null);
			}
		}
	
	}

}
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.ui.Mouse;
import flash.ui.MouseCursor;
import flash.ui.MouseCursorData;

class ButtonSprite extends Sprite
{
	private var cursorData:MouseCursorData;
	private var vectorBitmapData:Vector.<BitmapData> = new Vector.<BitmapData>(4, true);
	private var bitmapData:Vector.<BitmapData>;

	public function ButtonSprite():void
	{
		addEventListener(Event.ADDED_TO_STAGE, init);
	}
	
	public function init(e:Event):void
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		buttonMode = true;
		graphics.beginFill(0xFF0000, 0);
		graphics.drawRect(0, 0, Brush.w, Brush.h);
		graphics.endFill();
		
		addEventListener(MouseEvent.MOUSE_DOWN, onPress);
		addEventListener(MouseEvent.MOUSE_UP, onRelease);
		addEventListener(MouseEvent.ROLL_OVER, onReleaseOver);
		addEventListener(MouseEvent.ROLL_OUT, onReleaseOut);
		
		initMouseCursor();
		switchCursor(16,0);
	}
	
	private function initMouseCursor():void 
	{
		vectorBitmapData[0] = getCursorBmd(16, 0x0);
		vectorBitmapData[1] = getCursorBmd(16, 0xE7C56C);
		vectorBitmapData[2] = getCursorBmd(8, 0x0);
		vectorBitmapData[3] = getCursorBmd(8, 0xE7C56C);

		cursorData = new MouseCursorData();
		cursorData.hotSpot = new Point(16, 16);
		bitmapData = new Vector.<BitmapData>(1, true);
		bitmapData[0] = vectorBitmapData[0];
		cursorData.data = bitmapData;
		Mouse.registerCursor("myCursor", cursorData);
		Mouse.cursor = "myCursor";
	}
	
	private function getCursorBmd(__size:int, __color:Number):BitmapData 
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(__color);
		shape.graphics.drawCircle(__size,__size,__size);
		shape.graphics.endFill();

		var cursorShape:Shape = shape;
		var bitmapdata:BitmapData = new BitmapData(__size * 2, __size * 2, true, __color);
		bitmapdata.draw(cursorShape);
		return bitmapdata;
	}
	
	public function switchCursor(__size:int, __idx:int):void
	{
		cursorData.hotSpot = new Point(__size, __size);
		bitmapData[0] = vectorBitmapData[__idx];
		cursorData.data = bitmapData;
		Mouse.registerCursor("myCursor", cursorData);
		Mouse.cursor = "myCursor";
	}
	
	public function reset(__w:Number, __h:Number):void 
	{
		graphics.clear();
		graphics.beginFill(0xFF0000, 0);
		graphics.drawRect(0, 0, __w, __h);
		graphics.endFill();
	}
	
	public function destroy():void 
	{
		removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
		removeEventListener(MouseEvent.MOUSE_UP, onRelease);
		removeEventListener(MouseEvent.ROLL_OVER, onReleaseOver);
		removeEventListener(MouseEvent.ROLL_OUT, onReleaseOut);
		Mouse.cursor = MouseCursor.AUTO;
		buttonMode = false;
	}
	
	private function onPress(e:MouseEvent):void
	{
		Brush(e.target.parent).mousePressed = true;
	}
	
	private function onRelease(e:MouseEvent):void
	{
		Brush(e.target.parent).mousePressed = false;
	}

	private function onReleaseOver(e:MouseEvent):void
	{
		Mouse.cursor = "myCursor";
	}

	private function onReleaseOut(e:MouseEvent):void
	{
		Brush(e.target.parent).mousePressed = false;
		Mouse.cursor = MouseCursor.AUTO;
	}
}


internal class TailLine extends Bitmap
{
	// brush setting
	// 細: 4,50,3
	//*細: 5,50,4
	//*粗: 10,100,5
	// 粗: 8,100,5
	//*極細: 3,30,3
	static public const RADIUS:int = 10;
	static public const NUM_LINES:int = 100;
	static public const SEGMENT_LENGTH:int = 5;

	private var lines:Array;
	
	public function TailLine():void
	{
		addEventListener(Event.ADDED_TO_STAGE, init);
	}
	
	private function init(e:Event):void
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		bitmapData = new BitmapData(Brush.w, Brush.h, true, 0x00000000);
		
		lines = [];
		for (var i:int = 0; i < NUM_LINES; i++)
		{
			var radius:Number = Math.random() * RADIUS;
			var radian:Number = Math.random() * Math.PI * 2;
			
			var line:IKline = new IKline(SEGMENT_LENGTH);
			line.x = Math.cos(radian) * radius;
			line.y = Math.sin(radian) * radius;
			line.segmentNum = 8;
			line.gravity = 0.1;
			line.friction = .2 //Math.random() * 0.2 + 0.7;    
			line.color = 0x000000;
			lines.push(line);
		}
		
		addEventListener(Event.ENTER_FRAME, loop);
	}
	
	private function loop(evt:Event):void
	{
		var _x:Number = stage.mouseX;
		var _y:Number = stage.mouseY;
		
		bitmapData.lock();
		
		bitmapData.fillRect(bitmapData.rect, 0x00000000);
		
		var len:int = lines.length;
		var line:IKline;
		var i:int = 0;
		for (i = 0; i < len; i++)
		{
			line = IKline(lines[i]);
			line.nextFrame(_x, _y);
			bitmapData.draw(drawLine(line), new Matrix(1, 0, 0, 1, line.x-this.parent.x, line.y-this.parent.y));
		}
		bitmapData.unlock();
	}
	
	private function drawLine(line:IKline):Shape
	{
		var segments:Array = line.segments;
		var leng:int = segments.length;
		var shape:Shape = new Shape();
		var g:Graphics = shape.graphics;
		
		g.moveTo(segments[0].x, segments[0].y);
		for (var i:int = 0; i < leng - 2; i++)
		{
			var xc:Number = (segments[i].x + segments[i + 1].x) / 2;
			var yc:Number = (segments[i].y + segments[i + 1].y) / 2;
			
			g.lineStyle(1 - i / (leng - 2), line.color, 1 - i / (leng - 2));
			g.curveTo(segments[i].x, segments[i].y, xc, yc);
		}
		
		return shape;
	}
}

internal class IKline
{
	public var segments /*Segment*/:Array = [];
	
	public var x:Number = 0;
	public var y:Number = 0;
	
	public var segmentLeng:int = 20;
	public var segmentNum:int = 8;
	public var gravity:Number = 0;
	public var friction:Number = 3;
	public var color:uint = 0x000000;
	
	public function IKline(segmentLeng:Number):void
	{
		this.gravity = gravity;
		this.friction = friction;
		
		var segment:Segment = new Segment(0 * i);
		segments.push(segment);
		
		for (var i:int = 1; i < segmentNum; i++)
		{
			segment = new Segment(segmentLeng - 0.5 * i);
			segments.push(segment);
		}
	}
	
	public function nextFrame(_x:int, _y:int):void
	{
		drag(segments[0], _x, _y);
		for (var i:int = 1; i < segmentNum; i++)
		{
			var segmentA:Segment = segments[i];
			var segmentB:Segment = segments[i - 1];
			drag(segmentA, segmentB.x, segmentB.y);
		}
	}
	
	private function drag(segment:Segment, xpos:Number, ypos:Number):void
	{
		segment.next();
		
		var dx:Number = xpos - segment.x;
		var dy:Number = ypos - segment.y;
		var radian:Number = Math.atan2(dy, dx);
		segment.rotation = radian * 180 / Math.PI;
		
		var pin:Point = segment.getPin();
		var w:Number = pin.x - segment.x;
		var h:Number = pin.y - segment.y;
		
		segment.x = xpos - w;
		segment.y = ypos - h;
		segment.setVector();
		
		segment.vx *= friction;
		segment.vy *= friction;
		segment.vy += gravity;
	}
}

internal class Segment extends Sprite
{
	private var segmentLeng:Number;
	public var vx:Number = 0;
	public var vy:Number = 0;
	
	private var prevX:Number = 0;
	private var prevY:Number = 0;
	
	public function Segment(segmentLeng:Number):void
	{
		this.segmentLeng = segmentLeng;
	}
	
	public function next():void
	{
		x += vx;
		y += vy;
	}
	
	public function setVector():void
	{
		if (prevX)
			vx = x - prevX;
		if (prevY)
			vy = y - prevY;
		
		prevX = x;
		prevY = y;
	}
	
	public function getPin():Point
	{
		var angle:Number = rotation * Math.PI / 180;
		var xpos:Number = x + Math.cos(angle) * segmentLeng;
		var ypos:Number = y + Math.sin(angle) * segmentLeng;
		
		return new Point(xpos, ypos);
	}
}

internal class Mask extends Shape
{
	public function Mask():void
	{
		draw();
	}
	
	public function draw(edgeWidth:uint=165,diameter:uint=330):void
	{
		graphics.beginFill(0x0000FF);
		graphics.moveTo(diameter/2, 0);
		graphics.lineTo(diameter, edgeWidth);
		graphics.lineTo(diameter/2, edgeWidth*2);
		graphics.lineTo(0, edgeWidth);
		graphics.endFill();

	}
}