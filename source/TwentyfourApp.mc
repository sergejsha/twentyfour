using Toybox.Application;
using Toybox.WatchUi;

class TwentyfourApp extends Application.AppBase {

	private var viewModel;

    function initialize() {
        AppBase.initialize();
        viewModel = new TwentyfourViewModel();
    }

    // onStart() is called on application start up
    function onStart(state) { }

    // onStop() is called when your application is exiting
    function onStop(state) { }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new TwentyfourView(viewModel) ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
    	viewModel.onPropertiesChanged();
        WatchUi.requestUpdate();
    }
}
