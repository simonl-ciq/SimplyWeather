import Toybox.WatchUi;
import Toybox.Lang;

class SimplyWeatherDelegate extends WatchUi.BehaviorDelegate {
    /* Initialize and get a reference to the view, so that
     * user iterations can call methods in the main view. */
     var SWView as SimplyWeatherView;
     
    function initialize(view as SimplyWeatherView) {
        WatchUi.BehaviorDelegate.initialize();
        SWView = view;
    }
    
/*
    function onActionMenu() {
		return onMenu();
	}
*/

    function onMenu() {
        SWView.setWindDirectionToCompass();
    	WatchUi.requestUpdate();
        return true;
    }

    function onSelect() {
    	var windex = SWView.getWindIndex();
   	    SWView.setWindDirection(((windex + 1) % 17) as Number);
   		WatchUi.requestUpdate();
   		return true;
    }

(:notouch)
    function onKey(evt) {
    	var bKey = evt.getKey();
    	if (bKey == WatchUi.KEY_UP) {
	    	var windex = SWView.getWindIndex();
   		    SWView.setWindDirection(((windex + 16) % 17) as Number);
   			WatchUi.requestUpdate();
   			return true;
	    } else {
	        return false;
	    }
    }

(:touch)
    function onKey(evt) {
    	var bKey = evt.getKey();
    	if (bKey == WatchUi.KEY_ENTER) {
	    	var windex = SWView.getWindIndex();
   		    SWView.setWindDirection((windex + 16) % 17);
   			WatchUi.requestUpdate();
   			return true;
	    } else {
	        return false;
	    }
    }

(:touch)
    function onSwipe(evt) {
    	var direction = evt.getDirection();
    	var windex = SWView.getWindIndex();
		if (direction == WatchUi.SWIPE_LEFT) {
	        SWView.setWindDirection((windex + 1) % 17);
		} else if (direction == WatchUi.SWIPE_RIGHT) {
	        SWView.setWindDirection((windex + 16) % 17);
		}
    	WatchUi.requestUpdate();
        return true;
    }

}
