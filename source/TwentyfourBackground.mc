using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Graphics;

class TwentyfourBackground extends WatchUi.Drawable {

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };
        Drawable.initialize(dictionary);
    }

    function draw(dc) {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Application.getApp().getProperty("BackgroundColor"));
        dc.clear();
    }
}
