import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SimplyWeatherApp extends Application.AppBase {
	hidden var weatherView as SimplyWeatherView or Null;
	hidden var weatherGlanceView as SimplyWeatherGlanceView or Null;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
(:typecheck(disableGlanceCheck))
    function onStop(state as Dictionary?) as Void {
		Sensor.enableSensorEvents( null );
        if (weatherView != null) {
            weatherView.enablePosition(false);
        }
    }

    // Return the initial view of your application here
/*
    function getInitialView() as Array<Views or InputDelegates>? {
        weatherView = new SimplyWeatherView();
        return [ weatherView, new SimplyWeatherDelegate(weatherView) ] as Array<Views or InputDelegates>;
    }
*/

(:typecheck(disableGlanceCheck))
    function getInitialView() {
        weatherView = new SimplyWeatherView();
        return [ weatherView, new SimplyWeatherDelegate(weatherView) ];
    }

    // New app settings have been received so trigger a UI update
(:typecheck(disableGlanceCheck))
    function onSettingsChanged() {
    	if (weatherView != null) {
			weatherView.getSettings();
    	    WatchUi.requestUpdate();
    	}
    	if (weatherGlanceView != null) {
			weatherGlanceView.getTitle();
//    	    weatherGlanceView.requestUpdate();
    	    WatchUi.requestUpdate();
    	}
    }

(:glance)
    function getGlanceView() {
        weatherGlanceView = new SimplyWeatherGlanceView();
        return [ weatherGlanceView ];
    }

}

function getApp() as SimplyWeatherApp {
    return Application.getApp() as SimplyWeatherApp;
}