package pt.system.fb
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author ConstFlash
	 */
	
	public class Preloader extends MovieClip 
	{
		public function Preloader() {
			
		}
		
		public function resize(sW:int, sH:int):void {
			logo.x = sW / 2;
			logo.y = sH / 2 - 10;
		}
	}
}