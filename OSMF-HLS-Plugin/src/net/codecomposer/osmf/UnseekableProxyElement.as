/*****************************************************
 *  
 *  Copyright 2009 Adobe Systems Incorporated.  All Rights Reserved.
 *  
 *****************************************************
 *  The contents of this file are subject to the Mozilla Public License
 *  Version 1.1 (the "License"); you may not use this file except in
 *  compliance with the License. You may obtain a copy of the License at
 *  http://www.mozilla.org/MPL/
 *   
 *  Software distributed under the License is distributed on an "AS IS"
 *  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 *  License for the specific language governing rights and limitations
 *  under the License.
 *   
 *  
 *  The Initial Developer of the Original Code is Adobe Systems Incorporated.
 *  Portions created by Adobe Systems Incorporated are Copyright (C) 2009 Adobe Systems 
 *  Incorporated. All Rights Reserved. 
 *  
 *****************************************************/
package net.codecomposer.osmf
{
	import org.osmf.elements.ProxyElement;
	import org.osmf.elements.VideoElement;
	import org.osmf.events.SeekEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaPlayer;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.SeekTrait;
	import org.osmf.traits.TraitEventDispatcher;
	
	public class UnseekableProxyElement extends ProxyElement
	{
		private var _mediaPlayer:MediaPlayer;
		
		public function set mediaPlayer(newValue:MediaPlayer):void {
			// We need to know when playback completes and when the media
			// is rewound.
			if (_mediaPlayer !== newValue) {
				if (_mediaPlayer) {
					_mediaPlayer.removeEventListener(TimeEvent.COMPLETE, onComplete);
					_mediaPlayer.removeEventListener(SeekEvent.SEEKING_CHANGE, onSeekingChange);
				}
				_mediaPlayer = newValue;
				if (_mediaPlayer) {
					_mediaPlayer.addEventListener(TimeEvent.COMPLETE, onComplete);
					_mediaPlayer.addEventListener(SeekEvent.SEEKING_CHANGE, onSeekingChange);
				}
			}
		}
		
		public function get mediaPlayer():MediaPlayer {
			return _mediaPlayer;
		}
		
		public function UnseekableProxyElement(proxiedElement:MediaElement=null)
		{
			super(proxiedElement);
			
			enableSeeking(false);
		}
		
		private function onComplete(event:TimeEvent):void
		{
			// When playback completes, unblock seeking (i.e. so that we
			// can be rewound).
//			trace("Unblocking seeking");
			blockedTraits = new Vector.<String>();
			var seekTrait:SeekTrait = mediaPlayer.media.getTrait(MediaTraitType.SEEK) as SeekTrait;
			if (seekTrait) {
				// For some reason, autoRewind breaks with this plugin so we
				// have to do it manually.
				if (mediaPlayer && mediaPlayer.autoRewind) {
					seekTrait.seek(0);
				}
			}
			enableSeeking(false);
		}
		
		private function onSeekingChange(event:SeekEvent):void
		{
			if (event.seeking == false && event.time == 0)
			{
				// Prevent seeking.
				enableSeeking(false);
			}
		}
		
		private function enableSeeking(enable:Boolean):void
		{
			var traitsToBlock:Vector.<String> = new Vector.<String>();
			if (enable == false)
			{
//				trace("Blocking seeking");
				traitsToBlock.push(MediaTraitType.SEEK);
			}
			else {
//				trace("Unblocking seeking enable=true");
			}
			
			blockedTraits = traitsToBlock;
		}
	}
}