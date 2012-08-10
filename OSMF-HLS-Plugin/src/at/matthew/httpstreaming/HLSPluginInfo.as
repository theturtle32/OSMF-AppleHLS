package at.matthew.httpstreaming {
	import org.osmf.elements.VideoElement;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactoryItem;
	import org.osmf.media.MediaFactoryItemType;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.PluginInfo;
	import org.osmf.media.URLResource;
	
	public class HLSPluginInfo extends PluginInfo
	{
		public function HLSPluginInfo(mediaFactoryItems:Vector.<MediaFactoryItem>=null, mediaElementCreationNotificationFunction:Function=null)
		{
			if (mediaFactoryItems !== null) {
				trace("mediaFactoryItems already initialized and passed to HLSPluginInfo constructor.  This is unsupported.");
			}
			
			mediaFactoryItems = new Vector.<MediaFactoryItem>();
			mediaFactoryItems.push(
				new MediaFactoryItem(
					"at.matthew.httpstreaming.HLSPlugin",
					canHandleResourceFunction,
					mediaElementCreationFunction,
					MediaFactoryItemType.STANDARD
				)
			);

			super(mediaFactoryItems, mediaElementCreationNotificationFunction);
		}
		
		private function canHandleResourceFunction(resource:MediaResourceBase):Boolean {
			if (resource === null) {
				return false;
			}
			
			if (!(resource is URLResource)) {
				return false;
			}
			
			var urlResource:URLResource = resource as URLResource;
			if (urlResource.url.search(/(https?|file)\:\/\/.*?\.m3u8(\?.*)?/i) !== -1) {
				return true;
			}
			
			var contentType:Object = urlResource.getMetadataValue("content-type");
			if (contentType && contentType is String) {
				if ((contentType as String).search(/(application\/x-mpegURL|vnd.apple.mpegURL)/i) !== -1) {
					return true;
				}
			}
			
			return false;
		}
		
		private function mediaElementCreationFunction():MediaElement {
			var loader:HTTPStreamingM3U8NetLoader = new HTTPStreamingM3U8NetLoader();
			var element:VideoElement = new VideoElement(null, loader);
			return element;
		}
		
		override public function initializePlugin(resource:MediaResourceBase):void {
			
		}
	}
}