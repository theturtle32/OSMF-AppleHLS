package
{
	import at.matthew.httpstreaming.HLSPluginInfo;
	import at.matthew.httpstreaming.HTTPStreamingM3U8NetLoader;
	
	import flash.display.Sprite;
	
	import org.osmf.containers.MediaContainer;
	import org.osmf.elements.VideoElement;
	import org.osmf.events.MediaFactoryEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactory;
	import org.osmf.media.MediaFactoryItem;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.PluginInfoResource;
	import org.osmf.media.URLResource;
	import org.osmf.net.NetLoader;
	
	public class TestHLSVideo extends Sprite
	{
		public var player:MediaPlayer;
		public var container:MediaContainer;
		
		public static const STREAMING_MP4_PATH:String = "rtmp://cp67126.edgefcs.net/ondemand/mp4:mediapm/ovp/content/demo/video/elephants_dream/elephants_dream_768x428_24.0fps_408kbps.mp4";
		public static const HLS_TEST_PATH:String = "http://www.codecomposer.net/hls/bipbop/gear4/prog_index.m3u8";
		public static const APPLE_TEST:String = "http://developer.apple.com/resources/http-streaming/examples/basic-stream.html";
		public static const HLS_TEST:String = "http://www.codecomposer.net/hls/playlist.m3u8";
		
		public function TestHLSVideo()
		{
			initPlayer();
		}
		
		private function initPlayer():void {
			
			var factory:MediaFactory = new MediaFactory();
			factory.addEventListener(MediaFactoryEvent.PLUGIN_LOAD, handlePluginLoad);
			factory.addEventListener(MediaFactoryEvent.PLUGIN_LOAD_ERROR, handlePluginLoadError);
			factory.loadPlugin(new PluginInfoResource(new HLSPluginInfo()));
			
			//the pointer to the media
			var resource:URLResource = new URLResource( HLS_TEST );
			
			// Only need to specify content-type if the m3u8 playlist does not
			// have a .m3u8 extension.
//			resource.addMetadataValue("content-type", "application/x-mpegURL");
			
			var element:MediaElement = factory.createMediaElement(resource);
			if (element === null) {
				throw new Error("Unsupported media type!");
			}
			
			//the simplified api controller for media
			player = new MediaPlayer( element );
			player.autoRewind = false;
			player.bufferTime = 4;
			
			//the container (sprite) for managing display and layout
			container = new MediaContainer();
			container.addMediaElement( element );
			container.scaleX = 0.5;
			container.scaleY = 0.5;
			
			//Adds the container to the stage
			this.addChild( container );
		}
		
		private function handlePluginLoad(event:MediaFactoryEvent):void {
			var pluginType:String = "Unknown Plugin";
			if (event.resource is PluginInfoResource) {
				var item:MediaFactoryItem = (event.resource as PluginInfoResource).pluginInfo.getMediaFactoryItemAt(0);
				if (item) {
					pluginType = item.id;
				}
			}
			trace("Plugin \"" + pluginType + "\" loaded.");
		}
		
		private function handlePluginLoadError(event:MediaFactoryEvent):void {
			var pluginType:String = "Unknown Plugin";
			if (event.resource is PluginInfoResource) {
				var item:MediaFactoryItem = (event.resource as PluginInfoResource).pluginInfo.getMediaFactoryItemAt(0);
				if (item) {
					pluginType = item.id;
				}
			}
			trace("Plugin \"" + pluginType + "\" load error.");
		}
	}
}