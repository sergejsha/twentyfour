using Toybox.Graphics;
using Toybox.WatchUi;

class TwentyfourDrawable extends WatchUi.Drawable {

	private var iconsFont;
	private var viewModel;
	private var cx, cy, radius;

    function initialize(params) {
        Drawable.initialize(params);
        iconsFont = WatchUi.loadResource(Rez.Fonts.IconsFont);
    }

	function onLayout(dc, viewModel) {
		self.viewModel = viewModel;
		self.cx = dc.getWidth() / 2.0;
		self.cy = dc.getHeight() / 2.0;
		self.radius = (dc.getWidth() - ARC_WIDTH) / 2.0;
	}

	function draw(dc) {
		var events = viewModel.events;
		var size = events.size();
		
		for (var i = 0; i < size; i++) {
			var start = events.get(i);
			var end = events.get((i + 1) % size);
			var startDegree = timeToDegrees(start.getMomentInfo());
			var endDegree = timeToDegrees(end.getMomentInfo());
			
			if ((startDegree - endDegree).abs() > MAX_UNDRAWABLE_ARC_DEGREE) {
				drawArc(dc, getColor(start), startDegree, endDegree);
				
			} else if (size == 2 && i == 1) {
				drawCircle(dc, getColor(start));
			}
		}
		
		for (var i = 0; i < size; i++) {
			drawEvent(dc, events.get(i));
		}
	}
	
	private function drawArc(dc, color, startDegree, endDegree) {	
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.setPenWidth(ARC_WIDTH);
		dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, startDegree, endDegree);
	}

	private function drawCircle(dc, color) {	
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.setPenWidth(ARC_WIDTH);
		dc.drawCircle(cx, cy, radius);
	}
	
	private function drawEvent(dc, event) {
		var degree = timeToDegrees(event.getMomentInfo());
		if (event.getType() == Event.TYPE_NOW) {
			drawDotWithBorder(dc, degree, ARC_HALF_WIDTH);
		} else {
			drawHatchWithBorder(dc, degree, HATCH_WIDTH, HATCH_HEIGHT);
			var icon = getEventIcon(event);
			if (icon != null) {
				drawEventIcon(dc, degree, icon);
			}
		}
	}
	
	private static function drawEventIcon(dc, degree, icon) {
	
		var radians = degreesToRadians(degree);
		var cos = Math.cos(radians);
		var sin = Math.sin(radians);
	
		var r = dc.getWidth() / 2 - 30;
		var x = cx + r * cos;
		var y = cy + r * sin;
	
		dc.drawText(x, y, iconsFont, icon, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
	
	private static function drawHatchWithBorder(dc, degree, width, height) {
	
		var radians = degreesToRadians(degree);
		var cos = Math.cos(radians);
		var sin = Math.sin(radians);
		
		var r1 = dc.getWidth() / 2;
		var x1 = cx + r1 * cos;
		var y1 = cy + r1 * sin;

		var r2 = r1 - height;
		var x2 = cx + r2 * cos;
		var y2 = cy + r2 * sin;
		
		dc.setPenWidth(width + 4);
		dc.setColor(viewModel.colorBackground, Graphics.COLOR_TRANSPARENT);
		dc.drawLine(x1, y1, x2, y2);

		dc.setPenWidth(width);
		dc.setColor(viewModel.colorForeground, Graphics.COLOR_TRANSPARENT);
		dc.drawLine(x1, y1, x2, y2);
	}
	
	private static function drawDotWithBorder(dc, degree, radius) {
		var radians = degreesToRadians(degree);
		var cos = Math.cos(radians);
		var sin = Math.sin(radians);
		
		var x = cx + self.radius * cos;
		var y = cy + self.radius * sin;

		dc.setColor(viewModel.colorBackground, Graphics.COLOR_TRANSPARENT);
		dc.fillCircle(x, y, radius + 3);
		
		dc.setColor(viewModel.colorForeground, Graphics.COLOR_TRANSPARENT);
		dc.fillCircle(x, y, radius);
	}

	private static function getColor(event) {
		var arc = event.getArcType(); 
		switch (arc) {
			case Event.ARC_PASSED: return Graphics.COLOR_DK_GRAY;
			case Event.ARC_DAY: return Graphics.COLOR_ORANGE;
			case Event.ARC_NIGHT: return Graphics.COLOR_DK_BLUE;
			default: return Graphics.COLOR_LT_GRAY;
		}
	}
		
	private static function getEventIcon(event) {
		var arc = event.getType(); 
		switch (arc) {
			case Event.TYPE_SUNRISE: return "B";
			case Event.TYPE_SOLAR_NOON: return "A";
			case Event.TYPE_SUNSET: return "C";
			default: return null;
		}
	}
	
	private static function timeToDegrees(time) {
		var minutes = (time.hour * 60 + time.min) % MINUTES_IN_DAY;
		return 90.0 - 360.0 / MINUTES_IN_DAY * minutes;
	}
	
	private static function degreesToRadians(degree) {
		return 2.0 * Math.PI - Math.PI * degree / 180.0;
	}
	
	private static const HATCH_WIDTH = 2.0;
	private static const HATCH_HEIGHT = 12.0;
	private static const ARC_WIDTH = 8.0;
	private static const ARC_HALF_WIDTH = ARC_WIDTH / 2;
	private static const MINUTES_IN_DAY = 24 * 60;
	private static const MAX_UNDRAWABLE_ARC_DEGREE = 0.999;
}