using Toybox.Time;

class Event {
	private var moment;
	private var type;
	private var arcType;
	private var momentInfo;
	
	function initialize(moment, type, arcType) {
		self.moment = moment;
		self.type = type;
		self.arcType = arcType;
	}
	
	function getMoment() {
		return self.moment;
	}
	
	function getType() {
		return self.type;
	}
	
	function getArcType() {
		return self.arcType;
	}

	function getMomentInfo() {
		if (self.momentInfo == null) {
			self.momentInfo = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
		}
		return self.momentInfo;
	}
	
	function toString() {
		return formatType(self.type) 
			+ ", moment: " + formatMoment(self.moment) + " (" + self.moment.value() + ")"
			+ ", arc: " + formatArcType(self.arcType);
	}
	
	static function formatType(type) {
		switch(type) {
			case TYPE_NOW: return "now";
			case TYPE_SUNRISE: return "sunrise";
			case TYPE_SOLAR_NOON: return "solar noon";
			case TYPE_SUNSET: return "sunset";
			case TYPE_MIDNIGHT: return "midnight";
			default: return "Unknown(" + type + ")";
		}
	}
	
	static function formatArcType(type) {
		switch(type) {
			case ARC_PASSED: return "passed";
			case ARC_DAY: return "day";
			case ARC_NIGHT: return "night";
			default: return "Unknown(" + type + ")";
		}
	}
	
	private static function formatMoment(moment) {
    	if (moment == null) {
    		return "null";
    	}
        var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.day.format("%02d") + "." + info.month.format("%02d") + "." + info.year.toString() + " " + 
        	info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" + info.sec.format("%02d");
	}
	
	enum {
		TYPE_NOW,
		TYPE_SUNRISE,
		TYPE_SOLAR_NOON,
		TYPE_SUNSET,
		TYPE_MIDNIGHT
	}

	enum {
		ARC_PASSED,
		ARC_DAY,
		ARC_NIGHT
	} 
}
