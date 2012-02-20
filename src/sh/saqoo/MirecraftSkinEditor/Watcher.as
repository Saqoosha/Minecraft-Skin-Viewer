package sh.saqoo.MirecraftSkinEditor {

	import org.osflash.signals.Signal;

	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;


	/**
	 * @author Saqoosha
	 */
	public class Watcher {
		
		
		private var _changed:Signal = new Signal(File);
		public function get changed():Signal { return _changed; }
		private var _file:File;
		public function get file():File { return _file; }
		private var _time:Number;
		private var _timer:Timer;
		
		
		public function Watcher(file:File, interval:Number = 1000) {
			_timer = new Timer(interval);
			_timer.addEventListener(TimerEvent.TIMER, _onTimer);
			watch(file);
		}
		
		
		public function watch(file:File):void {
			_file = file;
			_time = _file.modificationDate.getTime();
			_timer.start();
		}
		
		
		public function unwatch():void {
			_timer.stop();
		}
		
		
		private function _onTimer(e:TimerEvent):void {
			var t:Number = _file.modificationDate.getTime();
			if (_time < t) {
				_time = t;
				_changed.dispatch(_file);
			}
		}
	}
}
