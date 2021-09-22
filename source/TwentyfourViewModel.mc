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
			events = Ring.Events.create(now, today, lat, lng);
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
	
	private static function createEvent(moment, type, arc) {
		return new Ring.Event(moment, Time.Gregorian.info(moment, Time.FORMAT_SHORT), type, arc);
	}
	
	private static const FORMAT_FLOAT = "%2.0d";
}
