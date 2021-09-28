using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

class TwentyfourViewModel {

	var colorForeground;
	var colorBackground;
	var useMilitaryTimeFormat;
	var timeFontSize;
	var timeVerticalPadding;

	var fields = {};
	var events = new EmptyEvents();
	
	private var waitingForPosition = false;
	private var positionDegrees = null;

	function initialize() {
		initalizeResources();
	
		var positionInfo = Position.getInfo();
        if (isPositionReliable(positionInfo)) {
	        setPositionDegrees(positionInfo);
	        
        } else {
	        waitingForPosition = true;
            Position.enableLocationEvents(
            	Position.LOCATION_CONTINUOUS,
            	method(:onPositionUpdated)
            );
        }
	}

	function updateProperties(app) {
	    colorForeground = app.getProperty("ForegroundColor");
	    colorBackground = app.getProperty("BackgroundColor");
	    useMilitaryTimeFormat = app.getProperty("UseMilitaryFormat");
	}

	function onPositionUpdated(positionInfo) {
		if (!waitingForPosition || !isPositionReliable(positionInfo)) {
			positionDegrees = null;
			return;
		}
	
		waitingForPosition = false;
		Position.enableLocationEvents(
			Position.LOCATION_DISABLE, 
			method(:onPositionUpdated)
		);
		
		setPositionDegrees(positionInfo);
	}

	function onUpdate() {
	
		var today = Time.today();
		var now = Time.now();

		updatePosition();
		updateHorizon(now, today);	
		updateBatteryField();
	}

	private function updateHorizon(now, today) {
		if (positionDegrees == null) {
			return;
		}
	
		var lat = positionDegrees[0];
		var lng = positionDegrees[1];

		if (events.isUpdateReqiured(now, lat, lng)) {
			events = createEvents(now, today, lat, lng);
			updateTimeToEventField(now, today);
		}
	}

	private function isPositionReliable(positionInfo) {
		return positionInfo != null && 
			positionInfo.accuracy != Position.QUALITY_NOT_AVAILABLE;
	}

	private function setPositionDegrees(positionInfo) {
		positionDegrees = positionInfo.position.toDegrees();
	}

	private function updatePosition() {	
		if (waitingForPosition) {
			return;
		}
		var positionInfo = Position.getInfo();
        if (isPositionReliable(positionInfo)) {
	        setPositionDegrees(positionInfo);
		}
	}
	
	private function updateBatteryField() {
		var value = System.getSystemStats().battery.format(FORMAT_FLOAT);
		fields[Field.TYPE_BATTERY] = new Field(value + "%");
	}
	
	private function updateTimeToEventField(now, today) {
		var text = events.getText1();
		var text2 = events.getText2();

		if (text == null) {
			fields[Field.TYPE_TIME_TO_EVENT] = null;
			return;
		}	
	
		if (text2 != null) {
			text = text + " | " + text2;
		}
		fields[Field.TYPE_TIME_TO_EVENT] = new Field(text);
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
	
	private static function createEvents(now, today, lat, lng) {
		
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
		
		return new Events(events.toArray(), now.value(), lat, lng, text1, text2);
	}

	private function initalizeResources() {
		self.timeFontSize = WatchUi.loadResource(Rez.Strings.timeFontSize).equals(FONT_SIZE_HUGE) ? Graphics.FONT_NUMBER_THAI_HOT : Graphics.FONT_NUMBER_HOT; 
		self.timeVerticalPadding = WatchUi.loadResource(Rez.Strings.timeVerticalPadding).toNumber();
	}

	private static const FONT_SIZE_HUGE = "HUGE";

	private static const sunCalc = new SunCalc();
	private static const FORMAT_FLOAT = "%2.0d";
	private static const ONE_DAY = new Time.Duration(Time.Gregorian.SECONDS_PER_DAY);
	private static const DEBUG = false;
}
