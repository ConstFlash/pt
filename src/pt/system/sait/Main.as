package pt.system.sait
{
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.display.Stage;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
	import pt.system.sait.Preloader;
	import pt.system.MyEvent;
	import swfadress.SWFAddress;
	import swfadress.SWFAddressEvent;
	import flash.display.LoaderInfo;
    import flash.events.NetStatusEvent;
    import flash.net.SharedObject;
    import flash.net.SharedObjectFlushStatus;
	import flash.net.navigateToURL;
	
	import com.google.analytics.AnalyticsTracker;
	import com.google.analytics.GATracker;
	
	/**
	 * ...
	 * @author ConstFlash.com
	 */
	
	
	public class Main extends MovieClip
	{
		Security.allowDomain("*");
		//private var tracker:AnalyticsTracker = new GATracker(stage, "UA-31097383-1", "AS3", false); 
		private var tracker:AnalyticsTracker = new GATracker(stage, "UA-31097383-5", "AS3", false); 
		
        private var mySo:SharedObject;
		
		private var _preloader:Preloader = new Preloader();
		private var request:URLRequest = new URLRequest("xml/xml.xml");
		private var requestSOL:URLRequest = new URLRequest("xml/solubility.xml");
		//private var request:URLRequest = new URLRequest("http://test.constflash.com/oxst.php?n=7");
		private var skinUrl:URLRequest = new URLRequest("periodic-table.swf");
		private var _loader:Loader = new Loader();
		private var _Pla:Object;
		private var _xmlPT:XML;
		private var _xmlSOL:XML;
		
		private var schetchik:int = 0;
		
		public function Main():void 
		{
			traceNew("MAIN");
			var domain:String = LoaderInfo(this.root.loaderInfo).parameters.domain;
			Security.allowDomain(domain);
			Security.allowInsecureDomain(domain);
			
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
			traceNew("INIT");
			removeEventListener(Event.ADDED_TO_STAGE, init);
			this.addChild(_preloader);
			var uldr:URLLoader = new URLLoader();
			uldr.addEventListener(Event.COMPLETE, load1XML);
            uldr.load(request);
		}
		
		private function initNet():void {
			tracker.trackEvent("Loader", "START");
			traceNew("INIT_NET");
			requestSOL = new URLRequest("script/xml/solub.php?m=" + Math.random());
			//request = new URLRequest("xml.xml?m=" + Math.random());
			SWFAddress.addEventListener(SWFAddressEvent.CHANGE, handleSWFAddress);
			this.addChild(_preloader);
			var uldrSOL:URLLoader = new URLLoader();
			uldrSOL.addEventListener(Event.COMPLETE, load1XML);
			uldrSOL.addEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			_preloader.resize(stage.stageWidth, stage.stageHeight);
            uldrSOL.load(requestSOL);
		}
		
		private function load1XML(event:Event):void {
			traceNew("LOAD SOLUBILITY XML");
			tracker.trackEvent("Loader", "SOL XML GOOD");
			_xmlSOL = new XML(event.target.data);
			_xmlSOL.ignoreWhite = true;
			
			
			request = new URLRequest("script/xml/oxst.php?m=" + Math.random());
			var uldr:URLLoader = new URLLoader();
			uldr.addEventListener(Event.COMPLETE, load2XML);
			uldr.addEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			_preloader.resize(stage.stageWidth, stage.stageHeight);
            uldr.load(request);
		}
		
		private function load2XML(event:Event):void {
			traceNew("LOAD GENERAL XML");
			_xmlPT = new XML(event.target.data);
			_xmlPT.ignoreWhite = true;
			
			tracker.trackEvent("Loader", "GEN XML GOOD");
			
			mySo = SharedObject.getLocal("periodic-table");
			traceNew("loaded value: " + mySo.data.savedValue + "\n");
			
			if(mySo.data.savedValue == 'true') {
				for (var i:int = 1; i < 12;i++ ){
					traceNew("result "+i+" : " + mySo.data["result" + i]);
					traceNew("time " + i + " : " + mySo.data["time" + i]);
					if(mySo.data["result" + i] != undefined) {
						_xmlPT.game.lvl[i - 1]["@result"] = mySo.data["result" + i];
						_xmlPT.game.lvl[i - 1]["@time"] = mySo.data["time" + i];
					}
				}
			} else {
            	for (var s:int = 1; s < 12;s++ ){
					mySo.data["result" + s] = 0;
					mySo.data["time" + s] = 0;
				}
				mySo.data.savedValue = "true";
				saveValue(1, 0, 0);
			}
			
			skinUrl = new URLRequest("swf/periodic-table.swf?m=" + Math.random());
			//perezapis(); // Функция перезаписи!!!!! для обработки сервера
			_loader.contentLoaderInfo.addEventListener(Event.INIT, skinLoadComplete); // Загружаем СКИН
			_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			_loader.load(skinUrl);
		}
		
		
// Loading SKIN
		private function skinLoadProgress(ev:ProgressEvent):void {
			if (ev.bytesTotal != 0) {
				//_preloader.getPerc(Math.round(100*ev.bytesLoaded / ev.bytesTotal));
			}
		}
		
		private function skinLoadComplete(ev:Event):void {
			tracker.trackEvent("Loader", "SKIN GOOD");
			traceNew("LOAD COMPLETE");
			this.removeChild(_preloader);
			_loader.contentLoaderInfo.removeEventListener(Event.INIT, skinLoadComplete); // Загружаем СКИН
			_loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, skinLoadProgress); //Процент Загрузки
			_Pla = _loader.content; //Объекту назначаем СКИН
			_Pla.createSkin(_xmlPT, _xmlSOL, stage.stageWidth, stage.stageHeight);
			_Pla.addEventListener(MyEvent.MY, ptEvent);
			
			if (SWFAddress.getValue().slice(1) != "") {
				goGoodTable(SWFAddress.getValue().slice(1));
			} else {
				_Pla.setParam(1000);
				SWFAddress.setTitle(_xmlPT.lang.icon1["@name"]);
			}
			this.mc.addChild(_Pla.general as MovieClip);
		}
		
		private function resizeHandler(e:Event):void {
			_Pla.resizeTable(stage.stageWidth, stage.stageHeight);
			_preloader.resize(stage.stageWidth, stage.stageHeight);
		}
		
		private function ptEvent(e:MyEvent):void {
			traceNew("LOADER "+e.MyType+"_"+e.MyNumber);
			switch (e.MyType){
				case "CLICK" :
					SWFAddress.setValue('/' + _xmlPT.pt.el[e.MyNumber]["@namelatin"]);
					SWFAddress.setTitle(_xmlPT.pt.el[e.MyNumber]["@name"] + " - " + _xmlPT.pt.el[e.MyNumber]["@namelatin"] + " (" + _xmlPT.pt.el[e.MyNumber]["@sym"]+")");
				break;
				case "TABLE" :
					SWFAddress.setValue('/');
				SWFAddress.setTitle(_xmlPT.lang.icon1["@name"]);
				break;
				case "GAME" :
					SWFAddress.setValue('/GAME');
					SWFAddress.setTitle(_xmlPT.lang.icon5["@name"]);
				break;
				case "SOLUBILITY" :
					SWFAddress.setValue('/SOLUBILITY');
					SWFAddress.setTitle(_xmlPT.lang.icon3["@name"]);
				break;
				case "SOLVKLETKA" :
					SWFAddress.setValue('/SOLUBILITY/' + e.MyArray[0]);
					SWFAddress.setTitle(e.MyArray[1]);
				break;
				case "ABOUT" :
					SWFAddress.setValue('/ABOUT');
					SWFAddress.setTitle(_xmlPT.lang.icon9["@name"]);
				break;
				case "NEWS" :
					SWFAddress.setValue('/NEWS');
					SWFAddress.setTitle(_xmlPT.lang.icon10["@name"]);
				break;
				case "LANG" :
					var req:URLRequest;
					if(_xmlPT.lang["@name"] == "English") {
						req = new URLRequest("http://periodic-table.ru"+SWFAddress.getValue());
					} else {
						req = new URLRequest("http://periodic-table-of-elements.org"+SWFAddress.getValue());
					}
					navigateToURL(req, "_self");
				break;
				case "RECORD" :
					tracker.trackEvent("NewHighScore", String(e.MyNumber));
					saveValue(e.MyNumber, e.MyArray[0], e.MyArray[1]);
				break;
			}
		}
		
		// SWFAddress handling
		private function handleSWFAddress(e:SWFAddressEvent) {
			if(String(e.value).slice(1) != "") {
				goGoodTable(String(e.value).slice(1));
			} else {
				tracker.trackPageview('/');
				_Pla.setParam(1001);
				SWFAddress.setTitle(_xmlPT.lang.icon1["@name"]);
			}
		}
		
		private function goGoodTable(TitleURL:String):void {
			var NN:int;
			traceNew(TitleURL);
			traceNew(TitleURL.slice(0, 10));
			
			switch (TitleURL.slice(0,10)){
				case "SOLUBILITY" :
					if(TitleURL == "SOLUBILITY") {
						tracker.trackPageview('/SOLUBILITY');
						NN = 1002;
						SWFAddress.setTitle(_xmlPT.lang.icon3["@name"]);
					} else {
						tracker.trackPageview('/' + TitleURL);
						var SolvArr:Array = getSolvArr(TitleURL.slice(11));
						NN = 10000 + SolvArr[0] * 100 + SolvArr[1];
						SWFAddress.setTitle(_xmlSOL.solubility["v" + SolvArr[0]]["l"+SolvArr[1]]["@name"]);
					}
				break;
				case "GAME" :
					tracker.trackPageview('/GAME');
					NN = 1003;
					SWFAddress.setTitle(_xmlPT.lang.icon5["@name"]);
				break;
				case "ABOUT" :
					tracker.trackPageview('/ABOUT');
					NN = 1004;
					SWFAddress.setTitle(_xmlPT.lang.icon9["@name"]);
				break;
				case "NEWS" :
					tracker.trackPageview('/NEWS');
					NN = 1005;
					SWFAddress.setTitle(_xmlPT.lang.icon10["@name"]);
				break;
				default:
					tracker.trackPageview('/' + TitleURL);
					NN = getId(TitleURL)
					SWFAddress.setTitle(_xmlPT.pt.el[NN - 1]["@name"] + " - " + _xmlPT.pt.el[NN - 1]["@namelatin"]+" ("+_xmlPT.pt.el[NN - 1]["@sym"]+")");
				break;
			}
			_Pla.setParam(NN);
		}
		
		
		// Coocies!!!
		private function saveValue(lvlI:int,resultI:int,timeI:int):void {
			mySo.data["result" + lvlI] = resultI;
			mySo.data["time" + lvlI] = timeI;
            
            var flushStatus:String = null;
            try {
                flushStatus = mySo.flush(10000);
            } catch (error:Error) {
                traceNew("Error...Could not write SharedObject to disk\n");
            }
            if (flushStatus != null) {
                switch (flushStatus) {
                    case SharedObjectFlushStatus.PENDING:
                        traceNew("Requesting permission to save object...\n");
                        mySo.addEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
                        break;
                    case SharedObjectFlushStatus.FLUSHED:
                        traceNew("Value flushed to disk.\n");
                        break;
                }
            }
        }
		
		private function onFlushStatus(event:NetStatusEvent):void {
            traceNew("User closed permission dialog...");
            switch (event.info.code) {
                case "SharedObject.Flush.Success":
                    traceNew("User granted permission -- value saved.");
                    break;
                case "SharedObject.Flush.Failed":
                    traceNew("User denied permission -- value not saved.");
                    break;
            }
            mySo.removeEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
        }
		
		private function getId(ss:String):int {
			var NN:int = int(_xmlPT.pt.el.(@["namelatin"] == ss)["@id"]);
			return NN;
		}
		
		private function getSolvArr(ss:String):Array {
			var Arr:Array = Arr = [int(_xmlSOL.solubility.*.*.(@["url"] == ss)["@idv"]), int(_xmlSOL.solubility.*.*.(@["url"] == ss)["@idl"])];
			return Arr;
		}
		
		private function traceNew(Stext:String):void {
			txt.text = txt.text + Stext + "\n";
		}
	}
}