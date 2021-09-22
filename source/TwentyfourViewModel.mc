using Toybox.Application;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Lang;

class TwentyfourViewModel {

	var colorForeground;
	var colorBackground;
	var useMilitaryTimeFormat;

	var fields = {};
	var events = new Ring.EmptyEvents();
	
	private var waitingForPosition = false;
	private var positionDegrees = null;

	function initialize() {
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

		// fixme: update screen once per minute
	
		updatePosition();
		updateHorizon(now, today);	
		updateTimeToEventField(now, today);
		updateBatteryField();
	}

	private function updateHorizon(now, today) {
		if (positionDegrees == null) {
			return;
		}
	
		var lat = positionDegrees[0];
		var lng = positionDegrees[1];

		if (events.isOutdated(now, lat, lng)) {
			events = Ring.Events.create(now, today, lat, lng);
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
	
	private static function timeBetweenMomentsAsString(from, to) {
		var totalMinutes = to.subtract(from).value() / 60;
		var hours = totalMinutes / 60;
		var minutes = totalMinutes.toLong() % 60;
		return hours.format("%d") + ":" + minutes.format("%02d");
	}
	
	private function updateTimeToEventField(now, today) {
		var index = events.getNowIndex();
		if (index < 0) {
			fields[Field.TYPE_TIME_TO_EVENT] = null;
			return;
		}
	
		var index1 = events.getNextEventIndexAfter(index);
		if (index1 < 0) {
			fields[Field.TYPE_TIME_TO_EVENT] = null;
			return;
		}

		var event = events.get(index);
		var text = timeBetweenMomentsAsString(event.getMoment(), events.get(index1).getMoment());
		var index2 = events.getNextEventIndexAfter(index1);
		if (index2 > -1) {
			var secondText = timeBetweenMomentsAsString(event.getMoment(), events.get(index2).getMoment());
			text = text + " | " + secondText;
		}
	
		fields[Field.TYPE_TIME_TO_EVENT] = new Field(text);
	}
	
	private static function createEvent(moment, type, arc) {
		return new Ring.Event(moment, Time.Gregorian.info(moment, Time.FORMAT_SHORT), type, arc);
	}
	
	private static function momentToDegrees(moment) {
		var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
		var minutesInDay = 24 * 60;
		var minutes = (info.hour * 60 + info.min) % minutesInDay;
		return 90.0 - 360.0 / minutesInDay * minutes;
	}
	
	private static const FORMAT_FLOAT = "%2.0d";
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
