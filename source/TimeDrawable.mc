using Toybox.Graphics;
using Toybox.WatchUi;

class TimeDrawable extends WatchUi.Drawable {

	private var model;
	private var x, y;

    function initialize(params) {
        Drawable.initialize(params);
    }

	function onLayout(dc, model) {
		self.model = model;
		self.x = dc.getWidth() / 2;
		self.y = dc.getHeight() / 2;
	}

	function draw(dc) {
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var timeFormat = "$1$:$2$";
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (model.useMilitaryTimeFormat) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var time = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
	
		dc.setColor(model.colorForeground, Graphics.COLOR_TRANSPARENT);
		dc.drawText(x, y, Graphics.FONT_NUMBER_THAI_HOT, time, JUSTIFY_CENTER);
	}
	
	private const JUSTIFY_CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
}