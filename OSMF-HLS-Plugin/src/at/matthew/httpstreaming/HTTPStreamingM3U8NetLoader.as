/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the at.matthew.httpstreaming package.
 *
 * The Initial Developer of the Original Code is
 * Matthew Kaufman.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** */
 
 package at.matthew.httpstreaming {
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.URLResource;
	import org.osmf.net.httpstreaming.HTTPNetStream;
	import org.osmf.net.httpstreaming.HTTPStreamingNetLoader;

	import flash.net.NetConnection;
	import flash.net.NetStream;
		

	public class HTTPStreamingM3U8NetLoader extends HTTPStreamingNetLoader
	{
		override public function canHandleResource(resource:MediaResourceBase):Boolean
		{
			if (resource !== null && resource is URLResource) {
				var urlResource:URLResource = URLResource(resource);
				if (urlResource.url.search(/(https?|file)\:\/\/.*?\.m3u8(\?.*)?/i) !== -1) {
					return true;
				}
				
				var contentType:Object = urlResource.getMetadataValue("content-type");
				if (contentType && contentType is String) {
					// If the filename doesn't include a .m3u8 extension, but
					// explicit content-type metadata is found on the
					// URLResource, we can handle it.  Must be either of:
					// - "application/x-mpegURL"
					// - "vnd.apple.mpegURL"
					if ((contentType as String).search(/(application\/x-mpegURL|vnd.apple.mpegURL)/i) !== -1) {
						return true;
					}
				}
			}
			return false;
		}
		
		override protected function createNetStream(connection:NetConnection, resource:URLResource):NetStream
		{
			var httpNetStream:HTTPNetStream = new HTTPNetStream(connection, new HTTPStreamingM3U8Factory(), resource);
		//	httpNetStream.manualSwitchMode = false; // set to false to use internal logic until we get OSMF to do it right
		//	httpNetStream.indexInfo = new HTTPStreamingIndexInfoString(resource.url);
			return httpNetStream;
		}
		
	}
}
