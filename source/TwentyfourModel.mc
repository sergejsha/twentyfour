using Toybox.Application;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Lang;

class TwentyfourModel {

	var colorForeground;
	var colorBackground;
	var useMilitaryTimeFormat;

	var events = new Events();
	var cache = new Cache();
	var fields = {};
	
	private var sunCalc = new SunCalc();
	private var waitingForPosition = false;
	private var positionRadians = null;

	function initialize() {
		var positionInfo = Position.getInfo();
        if (isPositionReliable(positionInfo)) {
	        setPositionRadians(positionInfo);
	        
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
			positionRadians = null;
			return;
		}
	
		waitingForPosition = false;
		Position.enableLocationEvents(
			Position.LOCATION_DISABLE, 
			method(:onPositionUpdated)
		);
		
		setPositionRadians(positionInfo);
	}

	function onUpdate() {
	
		var now = Time.now();
		var today = Time.today();
		if (today.greaterThan(now)) {
			now = Time.now();
		}
	
		updatePosition();
		updateSunEvents(now, today);
		updateTimeToEventField(now, today);
		updateBatteryField();
	}

	private function isPositionReliable(positionInfo) {
		return positionInfo != null && 
			positionInfo.accuracy != Position.QUALITY_NOT_AVAILABLE;
	}

	private function setPositionRadians(positionInfo) {
		positionRadians = positionInfo.position.toRadians();
	}

	private function updatePosition() {	
		if (waitingForPosition) {
			return;
		}
		var positionInfo = Position.getInfo();
        if (isPositionReliable(positionInfo)) {
	        setPositionRadians(positionInfo);
		}
	}
	
	private function updateSunEvents(now, today) {
		if (waitingForPosition || positionRadians == null) {
			return;
		}
	
		var lat = positionRadians[0];
		var lng = positionRadians[1];
		if (cache.isValid(lat, lng, now)) {
			return;
		}
		
		var sunrise = sunCalc.calculate(today, lat, lng, SunCalc.SUNRISE);
		var sunset = sunCalc.calculate(today, lat, lng, SunCalc.SUNSET);
		var noon = sunCalc.calculate(today, lat, lng, SunCalc.NOON);

		var scene = Scene.detect(sunrise, sunset);
		switch(scene) {
			case Scene.DAY_NIGHT: events.createDayNightEvents(sunrise, sunset, noon, now, today); break;
			case Scene.POLAR_NIGHT: events.createPolarNight(noon, now); break;
			case Scene.POLAR_DAY: events.createPolarDay(noon, now); break;
			case Scene.FROM_POLAR_DAY: events.createFromPolarDay(sunset, noon, now); break;
			case Scene.FROM_POLAR_NIGHT: events.createFromPolarNight(sunrise, noon, now); break;
			case Scene.TO_POLAR_DAY: events.createToPolarDay(sunrise, noon, now); break;
			case Scene.TO_POLAR_NIGHT: events.createToPolarNight(sunset, noon, now); break;
			default: throw new Lang.InvalidValueException("Unknown scene: " + scene);
		}
	}	
	
	private function updateBatteryField() {
		var value = System.getSystemStats().battery.format(FORMAT_FLOAT);
		fields[Field.TYPE_BATTERY] = new Field(value + "%");
	}
	
	private static function timeBetweenString(from, to) {
		var totalMinutes = to.subtract(from).value() / 60;
		var hours = totalMinutes / 60;
		var minutes = totalMinutes.toLong() % 60;
		return hours.format("%d") + ":" + minutes.format("%02d");
	}
	
	private function updateTimeToEventField(now, today) {
		if (events.size() < 2) {
			return;
		}
	
		var nowEventIndex = events.findEventIndexByType(Event.TYPE_NOW);
		if (nowEventIndex == -1) {
			return;
		} 
	
		var nextEventIndex = (nowEventIndex + 1) % events.size();
		var nextEvent = events.get(nextEventIndex);
		if (nextEvent == null) {
			return;
		}

		var value = null; 
		if (nextEvent.getType() == Event.TYPE_SOLAR_NOON) {
			var secondNextEventIndex = (nextEventIndex + 1) % events.size();
			var secondNextEvent = events.get(secondNextEventIndex);
			value = timeBetweenString(now, nextEvent.getMoment());
			if (secondNextEvent != null && secondNextEvent.getType() == Event.TYPE_SUNSET) {
				value = value + " | " + timeBetweenString(now, secondNextEvent.getMoment());
			}
			
		} else if (nextEvent.getType() == Event.TYPE_MIDNIGHT) {
			var lat = positionRadians[0];
			var lng = positionRadians[1];
			var tomorrow = today.add(ONE_DAY);
			var sunrise = sunCalc.calculate(tomorrow, lat, lng, SunCalc.SUNRISE);
			if (sunrise instanceof Time.Moment) {
				value = timeBetweenString(now, sunrise);
			}
			
		} else {
			value = timeBetweenString(now, nextEvent.getMoment());
		}
		
		if (value == null) {
			fields[Field.TYPE_TIME_TO_EVENT] = null;
		} else {
			fields[Field.TYPE_TIME_TO_EVENT] = new Field(value);
		}
	}
	
	private static function createEvent(moment, type, arc) {
		return new Event(moment, Time.Gregorian.info(moment, Time.FORMAT_SHORT), type, arc);
	}
	
	private static function momentToDegrees(moment) {
		var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
		var minutesInDay = 24 * 60;
		var minutes = (info.hour * 60 + info.min) % minutesInDay;
		return 90.0 - 360.0 / minutesInDay * minutes;
	}
	
	private static const ONE_DAY = new Time.Duration(Time.Gregorian.SECONDS_PER_DAY);
	private static const FORMAT_FLOAT = "%2.0d";
}

class Scene {
	enum {
		DAY_NIGHT,
		POLAR_NIGHT,
		POLAR_DAY,
		FROM_POLAR_DAY,
		FROM_POLAR_NIGHT,
		TO_POLAR_DAY,
		TO_POLAR_NIGHT		
	}
	
	static function detect(sunrise, sunset) {
		if (sunrise == SunCalc.Moment.ABOVE_HORIZONT) {
			if (sunset == SunCalc.Moment.ABOVE_HORIZONT) {
				return Scene.POLAR_DAY;
			} else {
				return Scene.FROM_POLAR_DAY;
			}
		} else if (sunset == SunCalc.Moment.BELOW_HORIZONT) {
			if (sunrise == SunCalc.Moment.BELOW_HORIZONT) {
				return Scene.POLAR_NIGHT;
			} else {
				return Scene.FROM_POLAR_NIGHT;
			}
		} else if (sunset == SunCalc.Moment.ABOVE_HORIZONT) {
			return Scene.TO_POLAR_DAY;
		} else if (sunrise == SunCalc.Moment.BELOW_HORIZONT) {
			return Scene.TO_POLAR_NIGHT;
		} else {
			return Scene.DAY_NIGHT;
		}
	}
} 

class Event {
	enum { TYPE_NOW, TYPE_SUNRISE, TYPE_SOLAR_NOON, TYPE_SUNSET, TYPE_MIDNIGHT }
	enum { ARC_PASSED, ARC_DAY, ARC_NIGHT } 

	private var moment;
	private var time;
	private var type;
	private var arc;
	
	function initialize(moment, time, type, arc) {
		self.moment = moment;
		self.time = time;
		self.type = type;
		self.arc = arc;
	}
	
	function getMoment() {
		return moment;
	}
	
	function getTime() {
		return time;
	}

	function getType() {
		return type;
	}

	function getArc() {
		return arc;
	}
}

class Field {
	enum {
		COMPARTMENT_TOP_LEFT, 
		COMPARTMENT_TOP_RIGHT, 
		COMPARTMENT_BOTTOM_RIGHT, 
		COMPARTMENT_BOTTOM_LEFT,
		COMPARTMENT_TOP_CENTER,
		COMPARTMENT_BOTTOM_CENTER
	}

	enum {
		TYPE_NONE, 
		TYPE_TIME_TO_EVENT, 
		TYPE_BATTERY
	}

	private var value;
	
	function initialize(value) {
		self.value = value;
	}
	
	function getValue() {
		return value;
	}
}

class Events {
	private var events;
	
	function size() {
		if (events == null) {
			return 0;
		} else {
			return events.size();
		}
	}
	
	function get(index) {
		return events[index];
	}
	
	function createDayNightEvents(sunrise, sunset, noon, now, today) {
		ensureSize(5);
	
		if (now.greaterThan(sunset)) {
			events[0] = createEvent(today, Event.TYPE_MIDNIGHT, Event.ARC_NIGHT);
			events[1] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_PASSED);
			events[2] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_PASSED);
			events[3] = createEvent(sunset, Event.TYPE_SUNSET, Event.ARC_PASSED);
			events[4] = createEvent(now, Event.TYPE_NOW, Event.ARC_NIGHT);
			
		} else if (now.greaterThan(noon)) {
			events[0] = createEvent(sunset, Event.TYPE_SUNSET, Event.ARC_NIGHT);
			events[1] = createEvent(today, Event.TYPE_MIDNIGHT, Event.ARC_PASSED);
			events[2] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_PASSED);
			events[3] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_PASSED);
			events[4] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
			
		} else if (now.greaterThan(sunrise)) {
			events[0] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY);
			events[1] = createEvent(sunset, Event.TYPE_SUNSET, Event.ARC_NIGHT);
			events[2] = createEvent(today, Event.TYPE_MIDNIGHT, Event.ARC_PASSED);
			events[3] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_PASSED);
			events[4] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
		
		} else {
			events[0] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_DAY);
			events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY);
			events[2] = createEvent(sunset, Event.TYPE_SUNSET, Event.ARC_PASSED);
			events[3] = createEvent(today, Event.TYPE_MIDNIGHT, Event.ARC_PASSED);
			events[4] = createEvent(now, Event.TYPE_NOW, Event.ARC_NIGHT);
		}
	}	
	
	function createPolarNightEvents(now, noon) {
		ensureSize(2);
		events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_NIGHT);
		events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_NIGHT);
	}
	
	function createPolarNight(noon, now) {
		ensureSize(2);
		events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_NIGHT);
		events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_NIGHT);
	}
	
	function createPolarDay(noon, now) {
		ensureSize(2);
		events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
		events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY);
	}
	
	function createFromPolarDay(sunset, noon, now) {
		ensureSize(3);
		if (now.greaterThan(noon) && now.lessThan(sunset)) {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
			events[1] = createEvent(sunset, Event.TYPE_SUNSET, Event.ARC_NIGHT);
			events[2] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_PASSED);
		} else {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
			events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY);
			events[2] = createEvent(sunset, Event.TYPE_SUNSET, Event.ARC_NIGHT);		
		}
	}
	
	function createFromPolarNight(sunrise, noon, now) {
		ensureSize(3);
		if (now.greaterThan(sunrise) && now.lessThan(noon)) {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_NIGHT);
			events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_NIGHT);
			events[2] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_DAY);
		} else {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_NIGHT);
			events[1] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_DAY);
			events[2] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY);
		}
	}
	
	function createToPolarDay(sunrise, noon, now) {
		ensureSize(3);
		if (now.greaterThan(sunrise) && now.lessThan(noon)) {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
			events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY);
			events[2] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_PASSED);
		} else {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
			events[1] = createEvent(sunrise, Event.TYPE_SUNRISE, Event.ARC_DAY);
			events[2] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_DAY);
		}
	}
	
	function createToPolarNight(sunset, noon, now) {
		ensureSize(3);
		if (now.greaterThan(noon) && now.lessThan(sunset)) {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_DAY);
			events[1] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_NIGHT);
			events[2] = createEvent(sunset, Event.TYPE_SUNRISE, Event.ARC_PASSED);
		} else {
			events[0] = createEvent(now, Event.TYPE_NOW, Event.ARC_NIGHT);
			events[1] = createEvent(sunset, Event.TYPE_SUNRISE, Event.ARC_NIGHT);
			events[2] = createEvent(noon, Event.TYPE_SOLAR_NOON, Event.ARC_NIGHT);
		}
	}
	
	function findEventIndexByType(type) {
		if (events == null) {
			return -1;
		} else {
			for (var i = 0; i < events.size(); i++) {
				 if (events[i].getType() == type) {
				 	return i;
				 }
			}
			return -1;
		}
	}
	
	private function ensureSize(size) {
		if (events == null || events.size() != size) {
			events = new [size];
		}
	}
	
	private static function createEvent(moment, type, arc) {
		return new Event(moment, Time.Gregorian.info(moment, Time.FORMAT_SHORT), type, arc);
	}	
}

class Cache {
	private var lat, lng, totalMinutes;
	
	function isValid(lat, lng, now) {
		var totalMinutes = now.value() / 60;
		var valid = self.lat == lat && self.lng == lng && self.totalMinutes == totalMinutes;
		if (!valid) {
			self.lat = lat;
			self.lng = lng;
			self.totalMinutes = totalMinutes;
		}
		return valid;
	}
}
