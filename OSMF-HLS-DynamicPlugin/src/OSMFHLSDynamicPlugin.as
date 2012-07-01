package
{
	import at.matthew.httpstreaming.HLSPluginInfo;
	
	import flash.display.Sprite;
	
	import org.osmf.media.PluginInfo;
	
	public class OSMFHLSDynamicPlugin extends Sprite
	{
		private var _pluginInfo:PluginInfo;
		
		public function OSMFHLSDynamicPlugin()
		{
			super();
			_pluginInfo = new HLSPluginInfo();
		}
		
		public function get pluginInfo():PluginInfo {
			return _pluginInfo;
		}
	}
}