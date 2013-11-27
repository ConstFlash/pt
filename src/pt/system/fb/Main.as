package pt.system.fb
{
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.display.Stage;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
	import pt.system.sait.Preloader;
	import pt.system.MyEvent;
	import flash.display.LoaderInfo;
    import flash.events.NetStatusEvent;
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONDecoder;
	import com.adobe.serialization.json.JSONEncoder;
	import com.adobe.serialization.json.*;
	
	import com.google.analytics.AnalyticsTracker;
	import com.google.analytics.GATracker;
	/**
	 * ...
	 * @author ConstFlash.com
	 */
	
	
	public class Main extends MovieClip
	{
		Security.allowDomain("*");
		private var tracker:AnalyticsTracker;
		
		private var _preloader:Preloader = new Preloader();
		private var skinUrl:URLRequest;
		private var _loader:Loader = new Loader();
		private var _Pla:Object;
		private var _xmlPT:XML;
		
		
		private var _accessToken:String;
		private var _myId:String;
		private var friendsStr:String = "";
		private var flashVars:Object;
		private var friends:Object;
		private var friendsall:Array = new Array();
		private var userInfo:Object;
		
		
		private var schetchik:int = 0;
		
		public function Main():void 
		{
			traceNew("MAIN");
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, resizeHandler);
			
			if (stage) initNet();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
			txt.visible = false;
			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent){ txt.visible = !txt.visible});
		}
		
		private function init(e:Event = null):void 
		{
			/*traceNew("INIT");
			removeEventListener(Event.ADDED_TO_STAGE, init);
			this.addChild(_preloader);
			var uldr:URLLoader = new URLLoader();
			uldr.addEventListener(Event.COMPLETE, loadXML);
            uldr.load(request);*/
		}
		
		private function initNet():void {
			flashVars = this.stage.loaderInfo.parameters as Object;
			userInfo = JSON.decode(flashVars.userInfo) as Object;
			_myId = userInfo.uid;
			if (userInfo.lang == "ru") {
				tracker = new GATracker(stage, "UA-31097383-2", "AS3", false); 
			} else if(userInfo.lang == "en") {
				tracker = new GATracker(stage, "UA-31097383-3", "AS3", false); 
			} else {
				tracker = new GATracker(stage, "UA-31097383-4", "AS3", false); 
			}
			tracker.trackEvent("Loader", "START");
			friends = JSON.decode(this.flashVars.friends);
			var friendsArr:Array = friends as Array;
				for (var i:int = 0; i < friendsArr.length; i++ ) {
					friendsStr = friendsStr + friendsArr[i].uid + ",";
				}
				friendsStr = friendsStr.slice(0,-1);
			var friendsObj:Object = JSON.decode(this.flashVars.friendsall);
			friendsall = friendsObj as Array;
				
			traceNew("INIT_NET");
			skinUrl = new URLRequest("../swf/periodic-table.swf?m=" + Math.random());
			this.addChild(_preloader);
			
			var xmlReq:URLRequest = new URLRequest("script/oxst.php?m=" + Math.random());
			xmlReq.method = URLRequestMethod.POST;
			var uldr:URLLoader = new URLLoader();
			uldr.addEventListener(Event.COMPLETE, loadXML);
			uldr.addEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			uldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void{traceNew("Error1")}); // Ошибка загрузки
            uldr.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void{traceNew("Error2")}); // Ошибка загрузки (перезагрузите приложение)
			var variables:URLVariables = new URLVariables();
			variables.friends = friendsStr;
			variables.myid = _myId;
			variables.email = userInfo.email;
			variables.first_name = userInfo.first_name;
			variables.last_name = userInfo.last_name;
			variables.gender = userInfo.gender;
			variables.locale = userInfo.locale;
			variables.birthday = userInfo.birthday;
			xmlReq.data = variables;
			
			_preloader.resize(stage.stageWidth, stage.stageHeight);
            uldr.load(xmlReq);
		}
		
		private function loadXML(event:Event):void {
			tracker.trackEvent("Loader", "XML GOOD");
			traceNew("LOAD XML");
			_xmlPT = new XML(event.target.data);
			_xmlPT.ignoreWhite = true;
			
			_loader.contentLoaderInfo.addEventListener(Event.INIT, skinLoadComplete); // Загружаем СКИН
			_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			_loader.load(skinUrl);
		}
		
		
// Loading SKIN
		private function skinLoadProgress(ev:ProgressEvent):void {
			if (ev.bytesTotal != 0) {
				//_preloader.getPerc(_xmlPT.pt.el[Math.round(100*ev.bytesLoaded / ev.bytesTotal)]["@sym"]);
			}
		}
		
		private function skinLoadComplete(ev:Event):void {
			tracker.trackEvent("Loader", "SKIN GOOD");
			traceNew("LOAD COMPLETE");
			this.removeChild(_preloader);
			_loader.contentLoaderInfo.removeEventListener(Event.INIT, skinLoadComplete); // Загружаем СКИН
			_loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			_Pla = _loader.content; //Объекту назначаем СКИН
			_Pla.createSkin(_xmlPT, stage.stageWidth, stage.stageHeight);
			_Pla.addEventListener(MyEvent.MY, ptEvent);
			
			_Pla.setParam(1000);
			tracker.trackPageview('/');
			
			this.mc.addChild(_Pla.general as MovieClip);
		}
		
		private function resizeHandler(e:Event):void {
			_Pla.resizeTable(stage.stageWidth, stage.stageHeight);
			_preloader.resize(stage.stageWidth, stage.stageHeight);
		}
		
		private function ptEvent(e:MyEvent):void {
			traceNew("LOADER "+e.MyType+"_"+e.MyNumber);
			switch (e.MyType) {
				case "CLICK" :
					tracker.trackPageview('/' + _xmlPT.pt.el[e.MyNumber]["@namelatin"]);
				break;
				case "TABLE" :
					tracker.trackPageview('/');
				break;
				case "GAME" :
					tracker.trackPageview('/GAME');
				break;
				case "SOLUBILITY" :
					tracker.trackPageview('/SOLUBILITY');
				break;
				case "RECORD" :
					tracker.trackEvent("NewHighScore", "START");
					tracker.trackEvent("NewHighScore", String(e.MyNumber));
					saveValue(int(e.MyNumber), int(e.MyArray[0]), (e.MyArray[1]));
				break;
			}
		}
		
		private function saveValue(lvl:int, score:int, time:int):void {
			traceNew("lvl: " + lvl + "; score: " + score + "; time: " + time);
			var xmlReqS:URLRequest = new URLRequest("script/highscore.php?m=" + Math.random());
			xmlReqS.method = URLRequestMethod.POST;
			var uldrS:URLLoader = new URLLoader();
			uldrS.addEventListener(Event.COMPLETE, saveValueComlete);
			uldrS.addEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			uldrS.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void{traceNew("ErrorSave1")}); // Ошибка загрузки
            uldrS.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void{traceNew("ErrorSave2")}); // Ошибка загрузки (перезагрузите приложение)
			var variablesS:URLVariables = new URLVariables();
			variablesS.friends = friendsStr;
			variablesS.myid = _myId;
			variablesS.score = score;
			variablesS.time = time;
			variablesS.lvl = lvl;
			xmlReqS.data = variablesS;
            uldrS.load(xmlReqS);
		}
		
		
		private function saveValueComlete(event:Event):void {
			tracker.trackEvent("NewHighScore", "COMPLETE");
			traceNew(event.target.data);
		}
		
		private function traceNew(Stext:String):void {
			txt.text = txt.text + Stext + "\n";
		}
	}
}