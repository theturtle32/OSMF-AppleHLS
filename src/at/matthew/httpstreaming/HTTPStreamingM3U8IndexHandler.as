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
	import __AS3__.vec.Vector;
	
	import flash.net.URLRequest;
	
	import org.osmf.events.HTTPStreamingEvent;
	import org.osmf.events.HTTPStreamingIndexHandlerEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.net.httpstreaming.HTTPStreamRequest;
	import org.osmf.net.httpstreaming.HTTPStreamRequestKind;
	import org.osmf.net.httpstreaming.HTTPStreamingIndexHandlerBase;
	import org.osmf.net.httpstreaming.HTTPStreamingUtils;
	import org.osmf.net.httpstreaming.flv.FLVTagScriptDataMode;
	import org.osmf.net.httpstreaming.flv.FLVTagScriptDataObject;
	import org.osmf.traits.TimeTrait;



	

	[Event(name="notifyIndexReady", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="notifyRates", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="notifyTotalDuration", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="requestLoadIndex", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="notifyError", type="org.osmf.events.HTTPStreamingFileIndexHandlerEvent")]
	[Event(name="DVRStreamInfo", type="org.osmf.events.DVRStreamInfoEvent")]
	
	public class HTTPStreamingM3U8IndexHandler extends HTTPStreamingIndexHandlerBase
	{
		private var _rateVec:Vector.<HTTPStreamingM3U8IndexRateItem>; // use vector instead?
		private var _urlBase:String;
		private var _loadingCount:int;
		private var _numRates:int;
		private var _segment:int;
		private var _absoluteSegment:int;
		private var _indexString:String; 
		
		override public function initialize(indexInfo:Object):void
		{
			if(indexInfo is String)
			{
				_indexString = String(indexInfo);
			}
			else if(indexInfo is HTTPStreamingIndexInfoString)
			{
				_indexString = (indexInfo as HTTPStreamingIndexInfoString).string;
			}
			else
				throw new Error("This manifest handler does not understand indexInfo that is not of type String or HTTPStreamingIndexInfoString");
		
			if(_indexString.toLowerCase().indexOf("http://") != 0 && _indexString.toLowerCase().indexOf("https://") == 0)
				throw new Error("This manifest handler does not understand indexInfo that does not appear to be a URL");
			
			// get the base part of the URL so that relative referenced URLs work
			var offset:int;
			offset = _indexString.lastIndexOf("/");
			_urlBase = _indexString.substr(0, offset+1);
				
			_rateVec = new Vector.<HTTPStreamingM3U8IndexRateItem>;	// deliberately losing reference to old one, if present
			
			var request:URLRequest;
		
			dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.REQUEST_LOAD_INDEX, false, false, false, 0, null, null, new URLRequest(_indexString), null, false));
		}	
	
		override public function dispose():void
		{
			
		}
		
		override public function processIndexData(data:*, indexContext:Object):void
		{
			if (indexContext == null)
			{
				_loadingCount = 0;
				_numRates = 0;
			}
			else
			{
				--_loadingCount;
				if (_absoluteSegment > 0) // we are reloading the manifest, so clear it out first
					(indexContext as HTTPStreamingM3U8IndexRateItem).clearManifest();
			}


			var lines:Array = String(data).split("\n");
			
			if(lines[0] != "#EXTM3U")
			{
				//throw new Error("Extended M3U files must start with #EXTM3U");
				trace("first line wasn't #EXTM3U was instead "+lines[0]); // have some files with weird data here
			}
			
			var i:int;
			for(i=1; i<lines.length; i++)
			{
				
				if(indexContext == null)
				{
					if(String(lines[i]).indexOf("#EXTINF:") == 0)
					{
						// this isn't a top-level file after all, it is a single-rate version...
						// so we:
						// bail out after this line and...
						i = lines.length+1;
						
						var rateItem:HTTPStreamingM3U8IndexRateItem = new HTTPStreamingM3U8IndexRateItem(1000, _indexString);
						_rateVec[_numRates++] = rateItem;
						_loadingCount++;
						dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.REQUEST_LOAD_INDEX, false, false, false, 0, null, null, new URLRequest(_indexString), rateItem, false));				
						
					}
				
					if(String(lines[i]).indexOf("#EXT-X-STREAM-INF:") == 0)
					{
						var offset:int = String(lines[i]).indexOf("BANDWIDTH=");
						offset += 10;
						var bw:Number = parseFloat( String(lines[i]).substr(offset));
						++i;
						if(i > lines.length)
							throw new Error("processIndexData: improperly terminated M3U8 file");
							
						var url:String;
						
						if(String(lines[i]).toLowerCase().indexOf("http://") == 0 || String(lines[i]).toLowerCase().indexOf("https://") == 0)
						{
							url = String(lines[i]);
						}
						else
						{
							url = _urlBase + String(lines[i]);
						}
						
						rateItem = new HTTPStreamingM3U8IndexRateItem(bw, url);
						_rateVec[_numRates++] = rateItem;
						_loadingCount++;
						dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.REQUEST_LOAD_INDEX, false, false, false, 0, null, null, new URLRequest(url), rateItem, false));					
					}
				}
				else
				{
					if(String(lines[i]).indexOf("#EXTINF:") == 0)
					{
						var duration:Number = parseFloat(String(lines[i]).substr(8));	// 8 is length of "#EXTINF:"
						
						++i;
						if(i > lines.length)
							throw new Error("processIndexData: improperly terminated M3U8 file (2)");
							
						if(String(lines[i]).toLowerCase().indexOf("http://") == 0 || String(lines[i]).toLowerCase().indexOf("https://") == 0)
						{
							url = String(lines[i]);
						}
						else
						{
							url = (indexContext as HTTPStreamingM3U8IndexRateItem).urlBase + String(lines[i]);
						}
						
						var manifestItem:HTTPStreamingM3U8IndexItem = new HTTPStreamingM3U8IndexItem(duration, url);
						(indexContext as HTTPStreamingM3U8IndexRateItem).addIndexItem(manifestItem);
					}
					if(String(lines[i]).indexOf("#EXT-X-ENDLIST") == 0)
					{
						//  This is not a live stream
						(indexContext as HTTPStreamingM3U8IndexRateItem).setLive(false);
					}
					if(String(lines[i]).indexOf("#EXT-X-MEDIA-SEQUENCE") == 0)
					{
						var sequence:Number = parseFloat(String(lines[i]).substr(22));	//22 is length of "#EXT-X-MEDIA-SEQUENCE:"
						(indexContext as HTTPStreamingM3U8IndexRateItem).setSequenceNumber(sequence); // Set rateItem.sequenceNumber = sequence;
					}	
				}
			}
			if (indexContext != null)
			{
					notifyTotalDuration((indexContext as HTTPStreamingM3U8IndexRateItem).totalTime, 0, (indexContext as HTTPStreamingM3U8IndexRateItem).live); // FIXME: we don't what rate context (quality level) we are processing, so just return quality 0
			}
			
			if(_loadingCount == 0 && _absoluteSegment == 0) // check for _absoluteSegement to make sure we are not reloading the manifest
			{
				_rateVec = _rateVec.sort(HTTPStreamingM3U8IndexRateItem.sortComparison);
				if((indexContext as HTTPStreamingM3U8IndexRateItem).live){
					var initialOffset:Number = (indexContext as HTTPStreamingM3U8IndexRateItem).totalTime - ( 
							( (indexContext as HTTPStreamingM3U8IndexRateItem).totalTime / (indexContext as HTTPStreamingM3U8IndexRateItem).manifest.length ) * 3); // Pantos spec section 6.3.3
					dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.INDEX_READY, false, false, true, initialOffset));
				} else {
					dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.INDEX_READY, false, false, false, 0));
				}
				
				var nameArray:Array = new Array;
				var rateArray:Array = new Array;
				
				for(i = 0; i<_rateVec.length; i++)
				{
					nameArray.push((_rateVec[i]).url);
					rateArray.push((_rateVec[i]).bw);
				}
				
				dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.RATES_READY, false, false, false, 0, nameArray, rateArray));
			}
		}
		
		override public function getFileForTime(time:Number, quality:int):HTTPStreamRequest
		{
			var item:HTTPStreamingM3U8IndexRateItem = _rateVec[quality];
			var manifest:Vector.<HTTPStreamingM3U8IndexItem> = item.manifest;
			var i:int;
			for(i = 0; i< manifest.length; i++)
			{
				if((time) < manifest[i].startTime)
					break;
			}
			if(i > 0)
				--i;
				
			_segment = i;
			_absoluteSegment = item.sequenceNumber + _segment; // we also need to set the absolute segment in case we are starting at an offset (live)
			return getNextFile(quality);	// so as to avoid duplicating code
		}

		override public function getNextFile(quality:int):HTTPStreamRequest
		{
			var item:HTTPStreamingM3U8IndexRateItem = _rateVec[quality];
			var manifest:Vector.<HTTPStreamingM3U8IndexItem> = item.manifest;
			var request:HTTPStreamRequest;
			var i:int;
			var currentTime:Number = 0;

			
			if(item.live)
			{
				
				if(_absoluteSegment == 0 && _segment == 0) // Initialize live playback
				{
					_absoluteSegment = item.sequenceNumber + _segment;
				}
				
				if(_absoluteSegment != (item.sequenceNumber + _segment)) // We re-loaded the live manifest, need to re-normalize the list
				{
					_segment = _absoluteSegment - item.sequenceNumber;
					if(_segment < 0)
					{
						_segment=0;
						_absoluteSegment = item.sequenceNumber;
					}
				}
				if(_segment >= manifest.length) // Try to force a reload
				{
					dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.REQUEST_LOAD_INDEX, false, false, item.live, 0, null, null, new URLRequest(_rateVec[quality].url), _rateVec[quality], false));						
					return new HTTPStreamRequest(HTTPStreamRequestKind.LIVE_STALL, null, 1.0);
				} 
			}
			
			if(_segment >= manifest.length)
			{
				return new HTTPStreamRequest(HTTPStreamRequestKind.DONE); 
			} 
			else
			{
				request = new HTTPStreamRequest(HTTPStreamRequestKind.DOWNLOAD, manifest[_segment].url);
				
				dispatchEvent(new HTTPStreamingEvent(HTTPStreamingEvent.FRAGMENT_DURATION, false, false, manifest[_segment].duration));
				++_segment;
				++_absoluteSegment;
			}
			
			if(item.live && _segment >= (manifest.length-1)) {  // Its a live stream and time to reload the manifest
				// TODO: Pantos spec says we should only refresh the manifest we care about... brute forcing this for now
				for(i = 0; i<_rateVec.length; i++)
				{
					dispatchEvent(new HTTPStreamingIndexHandlerEvent(HTTPStreamingIndexHandlerEvent.REQUEST_LOAD_INDEX, false, false, item.live, 0, null, null, new URLRequest(_rateVec[i].url), _rateVec[i], false));					
				}
			}		
			return request;
		}
		
		override public function dvrGetStreamInfo(indexInfo:Object):void
		{
		}
		
		private function notifyTotalDuration(duration:Number, quality:int, live:Boolean):void
		{
			var sdo:FLVTagScriptDataObject = new FLVTagScriptDataObject();
			var metaInfo:Object = new Object();
			if(!live)
				metaInfo.duration = duration;
			else
				metaInfo.duration = 0;

			sdo.objects = ["onMetaData", metaInfo];
			dispatchEvent(new HTTPStreamingEvent(HTTPStreamingEvent.SCRIPT_DATA, false, false , 0, sdo, FLVTagScriptDataMode.IMMEDIATE));
		}
	}
}