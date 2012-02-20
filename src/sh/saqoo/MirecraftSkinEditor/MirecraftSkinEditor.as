package sh.saqoo.MirecraftSkinEditor {

	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.loaders.Loader3D;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.textures.BitmapTexture;

	import com.bit101.components.CheckBox;
	import com.bit101.components.Label;
	import com.durej.PSDParser.PSDParser;

	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.net.URLRequest;


	[SWF(backgroundColor="0xffffff", frameRate="60", width="500", height="500")]
	public class MirecraftSkinEditor extends Sprite {


		[Embed(source='../bin/avatar.obj', mimeType='application/octet-stream')]
		private static const AvatarData:Class;

		private var _scene:Scene3D;
		private var _camera:Camera3D;
		private var _view:View3D;
		private var _cameraController:HoverController;
		private var _center:ObjectContainer3D;
		private var _avatar : Mesh;
		private var _watcher:Watcher;
		private var _alwaysOnTop:CheckBox;

		private var _move:Boolean = false;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;


		public function MirecraftSkinEditor() {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			_scene = new Scene3D();
			
			_camera = new Camera3D();
			_camera.lens.far = 2100;
			
			_view = new View3D();
			_view.antiAlias = 4;
			_view.backgroundColor = 0xbbcbff;
			_view.scene = _scene;
			_view.camera = _camera;
			addChild(_view);
			
			_view.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, _onDragEnter);
			_view.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, _onDragDrop);
			
			_center = new ObjectContainer3D();
			_center.y = 170;
			_cameraController = new HoverController(_camera, _center, 45, 10, 400);
			
			
			new Label(this, 3, 0, 'DROP SKIN FILE TO WINDOW TO PREVIEW. AUTOMATICALLY RELOADED WHEN IT UPDATES.');
			_alwaysOnTop = new CheckBox(this, 0, 0, 'ALWAYS ON TOP', _onCheckAlwaysOnTop);
			
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, _onResize);
			_onResize();
			
			Parsers.enableAllBundled();
			var loader:Loader3D = new Loader3D();
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, _onAssetComplete);
			loader.loadData(new AvatarData(), new AssetLoaderContext(false));
			_scene.addChild(loader);
		}


		private function _onCheckAlwaysOnTop(e:Event):void {
			stage.nativeWindow.alwaysInFront = CheckBox(e.target).selected;
		}
		
		
		private function _onDragEnter(e:NativeDragEvent):void {
			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
				var file:File = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
				if (file.url.match(/\.(png|jpg|gif|psd)$/i)) {
					NativeDragManager.acceptDragDrop(_view);
				}
			}
		}
		
		
		private function _onDragDrop(e:NativeDragEvent):void {
			var file:File = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
			_apply(file);
		}


		private function _onAssetComplete(e:AssetEvent):void {
			_avatar = e.asset as Mesh;
			_avatar.material = new ColorMaterial(0xff0000);
			_scene.addChild(_avatar);
			
			_apply(File.applicationDirectory.resolvePath('char.png'));
		}

		
		private function _apply(file:File):void {
			trace('url: ' + (file.url));
			if (_watcher) _watcher.unwatch();
			_watcher = new Watcher(file, 500);
			_watcher.changed.add(_onFileChanged);
			_onFileChanged(file);
		}


		private function _onFileChanged(file:File):void {
			if (file.url.match(/\.psd$/i)) {
				_loadPSD(file);
			} else {
				_loadImage(file);
			}
		}
		

		private function _loadPSD(file:File):void {
			file.load();
			file.addEventListener(Event.COMPLETE, function(e:Event):void {
				var parser:PSDParser = PSDParser.getInstance();
				file.data.position = 0;
				parser.parse(file.data);
				_setTexture(parser.composite_bmp);
			});
		}
		
		
		private function _loadImage(file:File):void {
			var loader:Loader = new Loader();
			loader.load(new URLRequest(file.url));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
				_setTexture(Bitmap(loader.content).bitmapData);
			});
		}
		
		
		private function _setTexture(bitmap:BitmapData):void {
			var scaled:BitmapData = new BitmapData(512, 256, true, 0x0);
			var mtx:Matrix = new Matrix(scaled.width / bitmap.width, 0, 0, scaled.height / bitmap.height);
			scaled.draw(bitmap, mtx, null, null, null, scaled.width < bitmap.width);
			var mat:TextureMaterial = new TextureMaterial(new BitmapTexture(scaled), true, false, false);
			mat.alphaThreshold = 0.99;
			_avatar.material = mat;
		}


		private function onMouseDown(event:MouseEvent):void {
			_lastPanAngle = _cameraController.panAngle;
			_lastTiltAngle = _cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
			_move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}


		private function onMouseUp(event:MouseEvent):void {
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}


		private function onStageMouseLeave(event:Event):void {
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}


		private function _onEnterFrame(event:Event):void {
			if (_move) {
				_cameraController.panAngle = 0.7 * (stage.mouseX - _lastMouseX) + _lastPanAngle;
				_cameraController.tiltAngle = 0.7 * (stage.mouseY - _lastMouseY) + _lastTiltAngle;
			}
			_view.render();
		}


		private function _onResize(event:Event = null):void {
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
			_alwaysOnTop.x = 3;
			_alwaysOnTop.y = stage.stageHeight - _alwaysOnTop.height - 6;
		}
	}
}
