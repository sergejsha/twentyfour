using Toybox.Graphics;
using Toybox.WatchUi;

class FieldDrawable extends WatchUi.Drawable {

	private var compartment;
	private var type;

	private var viewModel;
	private var x, y;
	private var justification;
	private var paddingY;

    function initialize(params) {
        Drawable.initialize(params);
        compartment = params[:compartment];
        type = params[:type];
    }

	function onLayout(dc, viewModel) {
		self.viewModel = viewModel;
		paddingY = viewModel.timeVerticalPadding;

		var cx = dc.getWidth() / 2;
		var cy = dc.getHeight() / 2;

		switch(compartment) {
			case Field.COMPARTMENT_TOP_LEFT:
				x = cx - DX;
				y = cy - paddingY;
				justification = Graphics.TEXT_JUSTIFY_RIGHT;
				break;
			
			case Field.COMPARTMENT_TOP_RIGHT:
				x = cx + DX;
				y = cy - paddingY;
				justification = Graphics.TEXT_JUSTIFY_LEFT;
				break;
				
			case Field.COMPARTMENT_BOTTOM_RIGHT:
				x = cx + DX;
				y = cy + paddingY;
				justification = Graphics.TEXT_JUSTIFY_LEFT;
				break;
			
			case Field.COMPARTMENT_BOTTOM_LEFT:
				x = cx - DX;
				y = cy + paddingY;
				justification = Graphics.TEXT_JUSTIFY_RIGHT;
				break;
				
			case Field.COMPARTMENT_TOP_CENTER:
				x = cx;
				y = cy - paddingY;
				justification = Graphics.TEXT_JUSTIFY_CENTER;
				break;
				
			case Field.COMPARTMENT_BOTTOM_CENTER:
				x = cx;
				y = cy + paddingY;
				justification = Graphics.TEXT_JUSTIFY_CENTER;
				break;
		}
	}

	function draw(dc) {
		if (type == Field.TYPE_NONE) {
			return;
		}
		
		var field = viewModel.fields[type];
		if (field == null) {
			return;
		}
		
		dc.setColor(viewModel.colorForeground, Graphics.COLOR_TRANSPARENT);
		dc.drawText(x, y, Graphics.FONT_SMALL, field.getValue(), justification | Graphics.TEXT_JUSTIFY_VCENTER);
	}
	
	private const DX = 11;
}
