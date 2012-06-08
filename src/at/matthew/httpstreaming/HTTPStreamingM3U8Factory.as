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

package at.matthew.httpstreaming
{
	import org.osmf.net.httpstreaming.HTTPStreamingFactory;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.net.httpstreaming.HTTPStreamingFileHandlerBase;
	import org.osmf.net.httpstreaming.HTTPStreamingIndexHandlerBase;
	import org.osmf.net.httpstreaming.HTTPStreamingIndexInfoBase;
	import org.osmf.media.URLResource;
	
	public class HTTPStreamingM3U8Factory extends HTTPStreamingFactory
	{
		public function HTTPStreamingM3U8Factory()
		{
			super();
		}
		
		override public function createFileHandler(resource:MediaResourceBase):HTTPStreamingFileHandlerBase
		{	
			return new HTTPStreamingMP2TSFileHandler();
		}
		override public function createIndexHandler(resource:MediaResourceBase, fileHandler:HTTPStreamingFileHandlerBase):HTTPStreamingIndexHandlerBase
		{
			return new HTTPStreamingM3U8IndexHandler(/* fileHandler */);
		}
		
		override public function createIndexInfo(resource:MediaResourceBase):HTTPStreamingIndexInfoBase
		{
			var urr:URLResource = resource as URLResource;
			return new HTTPStreamingIndexInfoString(urr.url);
		}
	}
}