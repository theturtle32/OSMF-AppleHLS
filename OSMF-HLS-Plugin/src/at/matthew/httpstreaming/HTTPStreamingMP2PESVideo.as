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
	import org.osmf.net.httpstreaming.flv.FLVTagVideo;

	import flash.utils.ByteArray;

	internal class HTTPStreamingMP2PESVideo extends HTTPStreamingMP2PESBase
	{
		private var _nalData:ByteArray;
		
		private var _vTag:FLVTagVideo;
		private var _vTagData:ByteArray;
		private var _scState:int;
		
		public function HTTPStreamingMP2PESVideo()
		{
			_scState = 0;
			_nalData = new ByteArray();
			_vTag = null;
			_vTagData = null;
		}
		
		override public function processES(pusi:Boolean, packet:ByteArray, flush:Boolean = false): ByteArray
		{
			if(pusi)
			{
				// start of a new PES packet
				
				if(packet.readUnsignedInt() != 0x1e0)
				{
						throw new Error("PES start code not found or not AAC/AVC");
				}
				// Ignore packet length and marker bits.
				packet.position += 3;
				// Need PTS and DTS
				var flags:uint = (packet.readUnsignedByte() & 0xc0) >> 6;
				if(flags & 0x03 !== 0x03) { 
					trace("video PES packet without both PTS and DTS");
				}
				
				if(flags != 0x03 && flags != 0x02)
				{
					throw new Error("video PES packet without PTS cannot be decoded");
				}
				// Check PES header length
				var length:uint = packet.readUnsignedByte();
				var pts:Number = 
					((packet.readUnsignedByte() & 0x0e) << 29) + 
					((packet.readUnsignedShort() & 0xfffe) << 14) + 
					((packet.readUnsignedShort() & 0xfffe) >> 1);
		
				length -= 5;
	
				if(flags == 0x03)
				{
					var dts:Number = 
						((packet.readUnsignedByte() & 0x0e) << 29) + 
						((packet.readUnsignedShort() & 0xfffe) << 14) + 
						((packet.readUnsignedShort() & 0xfffe) >> 1);
						
					_timestamp = Math.round(dts/90);
					_compositionTime =  Math.round(pts/90) - _timestamp;
					//trace("pts "+pts.toString()+" dts "+dts.toString()+" comp "+_compositionTime.toString() +" stamp "+_timestamp.toString() +" total "+(_compositionTime+_timestamp).toString());
					length -= 5;
				}
				else
				{
					_timestamp = Math.round(pts/90);
					_compositionTime = 0;
				}

				// Skip other header data.
				packet.position += length;
			}
			
			if(!flush)
				var dStart:uint = packet.position;	// assume that the copy will be from start-of-data

			var nals:Vector.<HTTPStreamingH264NALU> = new Vector.<HTTPStreamingH264NALU>;
			var nal:HTTPStreamingH264NALU;
			
			if(flush)
			{
				nal = new HTTPStreamingH264NALU(_nalData); // full length to end, don't need to trim last 3 bytes
				if(nal.NALtype != 0)
				{
					nals.push(nal); // could inline this (see below)	
					trace("pushed one flush nal of type "+nal.NALtype.toString());
				}
				_nalData = new ByteArray();
			}
			else while(packet.bytesAvailable > 0)
			{
				var value:uint = packet.readUnsignedByte();
				
				// finding only 3-byte start codes is ok as trailing zeros are ignored in most (all?) cases
				
				//trace("# "+value.toString(16) + "  at st "+_scState.toString());
				// unperf
				// _nalData.writeByte(value);	// in the future we will performance-fix this by keeping indexes and doing block copies, for now we want it to work at all
				switch(_scState)
				{
					case 0:
						if(value == 0x00)
							_scState = 1;
						break;
					case 1:
						if(value == 0x00)
							_scState = 2;
						else
							_scState = 0;
						break;
					case 2:
						if(value == 0x00)	// more than 2 zeros... no problem
						{
							// state stays at 2
							//trace("ex zero");
							break;
						}
						else if(value == 0x01)
						{
							// perf
							_nalData.writeBytes(packet, dStart, packet.position-dStart);
							dStart = packet.position;
							// at this point we have the NAL data plus the *next* start code in _nalData
							// unless there was no previous NAL in which case _nalData is either empty or has the leading zeros, if any
							if(_nalData.length > 4) // require >1 byte of payload
							{
								_nalData.length -= 3; // trim off the 0 0 1 (might be one more zero, but in H.264 that's ok)
								nal = new HTTPStreamingH264NALU(_nalData);
								if(nal.NALtype != 0)
								{
									//trace("F NAL TYPE "+nal.NALtype.toString());
									nals.push(nal); // could inline this as well, rather than stacking and processing later in the function	
								}
							}
							else
							{
								trace("length too short! = " + _nalData.length.toString());
							}
							_nalData = new ByteArray(); // and start collecting into the next one
							_scState = 0; // got one, now go back to looking
							break;
						}
						else
						{
							// trace("0, 0,... " + value.toString());
							_scState = 0; // go back to looking
							break;
						}
						// notreached
						break;
					default:
						// shouldn't ever get here
						_scState = 0;
						break;
				} // switch _scState
			} // while bytesAvailable
			
			if(!flush && packet.position-dStart > 0)
				_nalData.writeBytes(packet, dStart, packet.position-dStart);
					
			var spsNAL:HTTPStreamingH264NALU = null;
			var ppsNAL:HTTPStreamingH264NALU = null;
			
			// find  SPS + PPS if we can
			for each(nal in nals)
			{
				switch(nal.NALtype)
				{
					case 7:
						spsNAL = nal;
						break;
					case 8:
						ppsNAL = nal;
						break;
					default:
						break;
				}
			}
	
			var tags:Vector.<FLVTagVideo> = new Vector.<FLVTagVideo>;
			var tag:FLVTagVideo;
			var avccTag:FLVTagVideo = null;
						
			// note that this breaks if the sps and pps are in different segments that we process
			
			if(spsNAL && ppsNAL)
			{
				var spsLength:Number = spsNAL.length;
				var ppsLength:Number = ppsNAL.length;
				tag = new FLVTagVideo();
				
				tag.timestamp = _timestamp;
				tag.codecID = FLVTagVideo.CODEC_ID_AVC;
				tag.frameType = FLVTagVideo.FRAME_TYPE_KEYFRAME;
				tag.avcPacketType = FLVTagVideo.AVC_PACKET_TYPE_SEQUENCE_HEADER;
				
				var avcc:ByteArray = new ByteArray();
				
				avcc.writeByte(0x01); // avcC version 1
				// profile, compatibility, level
				avcc.writeBytes(spsNAL.NALdata, 1, 3);
				avcc.writeByte(0xff); // 111111 + 2 bit NAL size - 1
				avcc.writeByte(0xe1); // number of SPS
				avcc.writeByte(spsLength >> 8); // 16-bit SPS byte count
				avcc.writeByte(spsLength);
				avcc.writeBytes(spsNAL.NALdata, 0, spsLength); // the SPS
				avcc.writeByte(0x01); // number of PPS
				avcc.writeByte(ppsLength >> 8); // 16-bit PPS byte count
				avcc.writeByte(ppsLength);
				avcc.writeBytes(ppsNAL.NALdata, 0, ppsLength);
				
				tag.data = avcc;
				
				tags.push(tag);
				avccTag = tag;
			}
			
			for each(nal in nals)
			{
				//trace("   NAL TYPE "+nal.NALtype.toString());
				
				if(nal.NALtype == 9)	// AUD -  should read the flags in here too, perhaps
				{
					// close the last _vTag and start a new one
					if(_vTag && _vTagData.length == 0)
					{
						trace("zero-length vtag"); // can't happen if we are writing the AUDs in
						if(avccTag) trace(" avccts "+avccTag.timestamp.toString()+" vtagts "+_vTag.timestamp.toString());
					}
					
					if(_vTag && _vTagData.length > 0)
					{
						_vTag.data = _vTagData; // set at end (see below)
						tags.push(_vTag);
						if(avccTag)
						{
							avccTag.timestamp = _vTag.timestamp;
							avccTag = null;
						}
					}
					_vTag = new FLVTagVideo();
					_vTagData = new ByteArray(); // we assemble the nalus outside, set at end
					
					 _vTagData.writeUnsignedInt(nal.length);
					 _vTagData.writeBytes(nal.NALdata); // start with this very NAL, an AUD (XXX not sure this is needed)
					
					_vTag.codecID = FLVTagVideo.CODEC_ID_AVC;
					_vTag.frameType = FLVTagVideo.FRAME_TYPE_INTER; // adjust to keyframe later
					_vTag.avcPacketType = FLVTagVideo.AVC_PACKET_TYPE_NALU;
					_vTag.timestamp = _timestamp;
					_vTag.avcCompositionTimeOffset = _compositionTime;
				}
				else if(nal.NALtype != 7 && nal.NALtype != 8)
				{
					if(_vTag == null)
					{
						trace("needed to create vtag");
						_vTag = new FLVTagVideo();
						_vTagData = new ByteArray(); // we assemble the nalus outside, set at end
						_vTag.codecID = FLVTagVideo.CODEC_ID_AVC;
						_vTag.frameType = FLVTagVideo.FRAME_TYPE_INTER; // adjust to keyframe later
						_vTag.avcPacketType = FLVTagVideo.AVC_PACKET_TYPE_NALU;
						_vTag.timestamp = _timestamp;
						_vTag.avcCompositionTimeOffset = _compositionTime;	
					}
					
					
					if(nal.NALtype == 5) // is this correct code?
					{
						_vTag.frameType = FLVTagVideo.FRAME_TYPE_KEYFRAME;
					}
					
					_vTagData.writeUnsignedInt(nal.length);
					_vTagData.writeBytes(nal.NALdata);
				}
			}
			
			if(flush)
			{
				trace(" *** VIDEO FLUSH CALLED");
				if(_vTag && _vTagData.length > 0)
				{
					_vTag.data = _vTagData; // set at end (see below)
					tags.push(_vTag);
					if(avccTag)
					{
						avccTag.timestamp = _vTag.timestamp;
						avccTag = null;
					}
						
					trace("flushing one vtag");
				}
				
				_vTag = null; // can't start new one, don't have the info
			}
			
			var tagData:ByteArray = new ByteArray();
			
			for each(tag in tags)
			{
				//if(tag.avcPacketType == FLVTagVideo.AVC_PACKET_TYPE_SEQUENCE_HEADER)
				//	trace("seq header "+tag.timestamp.toString());
				//else
				//	trace("actually writing a tag time "+tag.timestamp.toString()+" comp "+tag.avcCompositionTimeOffset.toString());
				tag.write(tagData);
			}
			
			return tagData;
		}
	
	} // class
} // package