using Toybox.Application;
using Toybox.WatchUi;

class TwentyfourApp extends Application.AppBase {

	private var model;

    function initialize() {
        AppBase.initialize();
        model = new TwentyfourModel();
        model.updateProperties(self);
    }

    // onStart() is called on application start up
    function onStart(state) { }

    // onStop() is called when your application is exiting
    function onStop(state) { }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new TwentyfourView(model) ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
    	model.updateProperties(self);
        WatchUi.requestUpdate();
    }
}
