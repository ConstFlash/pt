package pt.system
{
	import flash.events.Event;
	
	public class MyEvent extends Event 
	{
		public static const MY:String = "btn";
		
		public var MyType:String;
		public var MyNumber:Number;
		public var MyArray:Array;
		
		public function MyEvent(MyType:String,MyNumber:Number,MyArray:Array)
		{
			super(MY);
			this.MyType = MyType;
			this.MyNumber = MyNumber;
			this.MyArray = MyArray;
		}
	}
}