using Toybox.Lang;
using Toybox.System;
using Toybox.Time;

module Ring {

	class Event {
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
	}
	
	class Events {
		private var events;
		private var sec, lat, lng;
		private var text1;
		private var text2;
	
		function initialize(events, sec, lat, lng, text1, text2) {
			self.events = events;
			self.sec = sec;
			self.lat = lat;
			self.lng = lng;
			self.text1 = text1;
			self.text2 = text2;
		}
		
		function getText1() {
			return text1;
		}
		
		function getText2() {
			return text2;
		}
		
		function get(index) {
			return events[index];
		}
		
		function size() {
			if (events == null) {
				return 0;
			} else {
				return events.size();
			}
		}
		
		function isUpdateReqiured(now, lat, lng) {
			return (now.value() - self.sec).abs() > 60 || self.lat != lat || self.lng != lng;
		}
		
		private static function isPolarDay(moment, lat) {
			var north = lat > 0;
			var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
			var summer = info.month > 4 && info.month < 10;
			return (north && summer) || (!north && !summer);
		}
		
		private static function timeBetweenMomentsAsString(from, to) {
			var totalMinutes = to.subtract(from).value() / 60;
			var hours = totalMinutes / 60;
			var minutes = totalMinutes.toLong() % 60;
			return hours.format("%d") + ":" + minutes.format("%02d");
		}
		
		static function create(now, today, lat, lng) {
			
			var text1 = null;
			var text2 = null;
			var times = sunCalc.getTimes(today, lat, lng, 0);
			var noon = times[:solarNoon];
			var sunrise = times[:sunrise];
			var sunset = times[:sunset];
			
			var events = new List(5);
			if (sunrise == null || sunset == null) {
				if (isPolarDay(now, lat)) {
					if (DEBUG) {
						System.println("polar day");
					}
					events.add(new Event(today, Event.TYPE_MIDNIGHT, Event.ARC_DAY));
					events.add(new Event(now, Event.TYPE_NOW, Event.ARC_DAY));
					text1 = "Polar day";
					
				} else {
					if (DEBUG) {
						System.println("polar night");
					}
					events.add(new Event(today, Event.TYPE_MIDNIGHT, Event.ARC_NIGHT));
					events.add(new Event(now, Event.TYPE_NOW, Event.ARC_NIGHT));
					text1 = "Polar night";
				}
				
			} else if (now.lessThan(noon)) { // before noon 
				if (now.lessThan(sunrise)) {
					if (DEBUG) {
						System.println("before sunrise");
					}
					events.add(new Event(today, Event.TYPE_MIDNIGHT, Event.ARC_PASSED));
					events.add(new Event(now, Event.TYPE_NOW, Event.ARC_NIGHT));
					events.add(new Event(sunrise, Event.TYPE_SUNRISE, Event.ARC_DAY));
					events.add(new Event(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY));
					events.add(new Event(sunset, Event.TYPE_SUNSET, Event.ARC_PASSED));
					text1 = timeBetweenMomentsAsString(now, sunrise);
					
				} else {
					if (DEBUG) {
						System.println("after sunrise");
					}
					events.add(new Event(today, Event.TYPE_MIDNIGHT, Event.ARC_PASSED));
					events.add(new Event(sunrise, Event.TYPE_SUNRISE, Event.ARC_PASSED));
					events.add(new Event(now, Event.TYPE_NOW, Event.ARC_DAY));
					events.add(new Event(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY));
					events.add(new Event(sunset, Event.TYPE_SUNSET, Event.ARC_NIGHT));
					text1 = timeBetweenMomentsAsString(now, noon);
					text2 = timeBetweenMomentsAsString(now, sunset);
				}
				
			} else { // after noon
				var tomorrow = today.add(ONE_DAY);
				if (now.lessThan(sunset)) {
					if (DEBUG) {
						System.println("before sunset");
					}
					events.add(new Event(tomorrow, Event.TYPE_MIDNIGHT, Event.ARC_PASSED));
					events.add(new Event(sunrise, Event.TYPE_SUNRISE, Event.ARC_PASSED));
					events.add(new Event(noon, Event.TYPE_SOLAR_NOON, Event.ARC_PASSED));
					events.add(new Event(now, Event.TYPE_NOW, Event.ARC_DAY));
					events.add(new Event(sunset, Event.TYPE_SUNSET, Event.ARC_NIGHT));
					text1 = timeBetweenMomentsAsString(now, sunset);
				
				} else { 
					if (DEBUG) {
						System.println("after sunset");
					}
				
					var tomorrowTimes = sunCalc.getTimes(tomorrow, lat, lng, 0);
					var tomorrowSunrise = tomorrowTimes[:sunrise];
			
					if (tomorrowSunrise == null) {
						if (isPolarDay(tomorrow, lat)) {
							if (DEBUG) {
								System.println("going into polar day");
							}
							events.add(new Event(tomorrow, Event.TYPE_MIDNIGHT, Event.ARC_DAY));
							text1 = "Polar day";
							
						} else {
							if (DEBUG) {
								System.println("going into polar night");
							}
							events.add(new Event(tomorrow, Event.TYPE_MIDNIGHT, Event.ARC_NIGHT));
							text1 = "Polar night";
						}
						events.add(new Event(noon, Event.TYPE_SOLAR_NOON, Event.ARC_PASSED));
						events.add(new Event(sunset, Event.TYPE_SUNSET, Event.ARC_PASSED));
						events.add(new Event(now, Event.TYPE_NOW, Event.ARC_NIGHT));
						
					} else {
						events.add(new Event(tomorrow, Event.TYPE_MIDNIGHT, Event.ARC_NIGHT));
						events.add(new Event(tomorrowSunrise, Event.TYPE_SUNRISE, Event.ARC_PASSED));
						events.add(new Event(noon, Event.TYPE_SOLAR_NOON, Event.ARC_PASSED));
						events.add(new Event(sunset, Event.TYPE_SUNSET, Event.ARC_PASSED));
						events.add(new Event(now, Event.TYPE_NOW, Event.ARC_NIGHT));
						text1 = timeBetweenMomentsAsString(now, tomorrowSunrise);
					}
				}
			}
			
			return new Ring.Events(events.toArray(), now.value(), lat, lng, text1, text2);
		}

		private static const sunCalc = new SunCalc();
		
		private static const ONE_DAY = new Time.Duration(Time.Gregorian.SECONDS_PER_DAY);
		private static const DEBUG = false;
	}
	
	class EmptyEvents {
		function size() {
			return 0;
		}
		
		function isUpdateReqiured(now, lat, lng) {
			return true;
		}
	}

	function formatMoment(moment) {
    	if (moment == null) {
    		return "null";
    	}
        var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.day.format("%02d") + "." + info.month.format("%02d") + "." + info.year.toString() + " " + 
        	info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" + info.sec.format("%02d");
	}
}