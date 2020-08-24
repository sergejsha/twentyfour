using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;

class TwentyfourView extends WatchUi.WatchFace {

	private var model;

    function initialize(model) {
	    self.model = model;
        WatchFace.initialize();
    }

    function onLayout(dc) {
		var layout = Rez.Layouts.WatchFace(dc);
		onLayoutDrawables(dc, layout);
        setLayout(layout);
    }

	private function onLayoutDrawables(dc, layout) {
		var size = layout.size();
		for (var i = 0; i < size; i++) {
			var drawable = layout[i];
			if (drawable has :onLayout) {
				drawable.onLayout(dc, model);
			}
		}
	}

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
    	model.onUpdate();
    	View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }
}
