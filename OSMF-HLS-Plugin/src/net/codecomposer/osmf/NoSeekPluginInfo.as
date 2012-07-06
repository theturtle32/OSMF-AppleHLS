package net.codecomposer.osmf
{
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactoryItem;
	import org.osmf.media.MediaFactoryItemType;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.PluginInfo;
	import org.osmf.media.URLResource;
	
	public class NoSeekPluginInfo extends PluginInfo
	{
		private var mediaPlayer:MediaPlayer;
		
		public function NoSeekPluginInfo(mediaFactoryItems:Vector.<MediaFactoryItem>=null, mediaElementCreationNotificationFunction:Function=null)
		{
			mediaFactoryItems = new Vector.<MediaFactoryItem>();
			var item:MediaFactoryItem = new MediaFactoryItem(
				"net.codecomposer.osmf.NoSeekPlugin",
				canHandleResourceFunction,
				mediaElementCreationFunction,
				MediaFactoryItemType.PROXY
			);
			mediaFactoryItems.push(item);
			
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
			
			var contentType:Object = urlResource.getMetadataValue("at.matthew.httpstreaming.content_type");
			if (contentType && contentType is String) {
				if ((contentType as String).search(/(application\/x-mpegURL|vnd.apple.mpegURL)/i) !== -1) {
					return true;
				}
			}
			
			return false;
		}
		
		private function mediaElementCreationFunction():MediaElement {
			var element:UnseekableProxyElement = new UnseekableProxyElement(null);
			element.mediaPlayer = mediaPlayer;
			return element;
		}
		
		override public function initializePlugin(resource:MediaResourceBase):void {
			mediaPlayer = resource.getMetadataValue("MediaPlayer") as MediaPlayer;
		}
	}
}