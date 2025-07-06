import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Position;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Activity;

import Zambretti;

const cLowPressure = 950;
const cHighPressure = 1050;
const cOffset = 0;
const cTime = 0.0 - ((Gregorian.SECONDS_PER_HOUR * 3) + (Gregorian.SECONDS_PER_MINUTE * 10));
const cSteady = 5.0; // equivalent to 0.5 hPa
const cShowTemperature = true;
const cUseMSLPressure = true;

/*
const HOURS_3_20 = ((Gregorian.SECONDS_PER_HOUR * 3) + (Gregorian.SECONDS_PER_MINUTE * 20));
const MINS_10 = (Gregorian.SECONDS_PER_MINUTE * 10);
const HOURS_1_10 = ((Gregorian.SECONDS_PER_HOUR * 1) + (Gregorian.SECONDS_PER_MINUTE * 10));
const HOURS_6_30 = (Gregorian.SECONDS_PER_HOUR * 6) + (Gregorian.SECONDS_PER_MINUTE * 30);
const MINS_15 = (Gregorian.SECONDS_PER_MINUTE * 15);
*/
const MINS_5 = (Gregorian.SECONDS_PER_MINUTE * 5);

//var gSensorHeading = 0;

class SimplyWeatherView extends WatchUi.View {
	var mUseMSLPressure as Boolean = true;
	var mLowPressure as Number = cLowPressure;
	var mHighPressure as Number = cHighPressure;
	var mOffset as Number = cOffset;
	var mUseOriginal as Boolean = false;
	var mTime as Float = cTime;
	var mSteadyLimit as Float = cSteady;
	var mNorthSouth as Number = 1; // Northern hemisphere
	var mDefHemi as Number = 1; // default hemisphere is Northern
	var mShowTemperature as Boolean = true;
	var mNotMetricTemp as Boolean = false;
	var mUseExternal as Boolean = false;
	var mSensorTemperature as String = "";

	var mWind as String = "Calm";
	var mDir as Number = 0;
	var mAcquiringGPS as Boolean = true;
	var acquiringGPS as String = "Acquiring GPS";

	var mRad90 as Lang.Decimal = 0.0;

//	var trendStrings = ["Steady", "Rising", "Falling"];
	var trendStrings as Array<Lang.ResourceId> = [
		Rez.Strings.TrendS,
		Rez.Strings.TrendR,
		Rez.Strings.TrendF
	] as Array<Lang.ResourceId>;

	var pointStrings as Array<Lang.ResourceId> = [
		Rez.Strings.C,
		Rez.Strings.N,
		Rez.Strings.NNE,
		Rez.Strings.NE,
		Rez.Strings.ENE,
		Rez.Strings.E,
		Rez.Strings.ESE,
		Rez.Strings.SE,
		Rez.Strings.SSE,
		Rez.Strings.S,
		Rez.Strings.SSW,
		Rez.Strings.SW,
		Rez.Strings.WSW,
		Rez.Strings.W,
		Rez.Strings.WNW,
		Rez.Strings.NW,
		Rez.Strings.NNW
	] as Array<Lang.ResourceId>;

	function tString(tr as Number) as String {
/*		
//			return WatchUi.loadResource(trendStrings[tr]);
			var myResource = (trendStrings as Array)[tr] as Lang.ResourceId;
			return WatchUi.loadResource(myResource);
*/
			return WatchUi.loadResource((trendStrings as Array)[tr] as Lang.ResourceId) as String;
	}

	function pString(dir as Number) as String {
			return WatchUi.loadResource((pointStrings as Array)[dir] as Lang.ResourceId) as String;
	}

    function getSettings() as Void {
        var temp;

		var deviceSettings = System.getDeviceSettings();
		mNotMetricTemp = deviceSettings.temperatureUnits != System.UNIT_METRIC;
        mRad90 = Math.toRadians(90.0d);

		try {
	        temp = Properties.getValue("AdjustedPressure");
		}
		catch (ex) {
			temp = null;
		}
       	mUseMSLPressure = (temp != null && temp instanceof Number) ? (temp == 0) : cUseMSLPressure;
		try {
	        temp = Properties.getValue("LowPressure");
		}
		catch (ex) {
			temp = null;
		}
		try {
		    if (!(temp instanceof Number)) {
				temp = cLowPressure;
			}
		    if (temp >= 850 && temp <= 1100) {
				mLowPressure = temp;
			}
		}
		catch (ex) {
			mLowPressure = cLowPressure;
		}
		try {
	        temp = Properties.getValue("HighPressure");
		    if (!(temp instanceof Number)) {
				temp = cHighPressure;
			}
		    if (temp >= 850 && temp <= 1100) {
				mHighPressure = temp;
			}
		}
		catch (ex) {
			mHighPressure = cHighPressure;
		}
	    if (mHighPressure < mLowPressure) {
			temp = mHighPressure;
			mHighPressure = mLowPressure;
			mLowPressure = temp;
		}
		try {
			temp = Properties.getValue("Offset");
		}
		catch (ex) {
			temp = cOffset;
		}
	    if (!(temp instanceof Number)) {
			temp = cOffset;
		}
	    mOffset = temp;
		try {
			temp = Properties.getValue("Steady");
		}
		catch (ex) {
			temp = null;
		}
	    mSteadyLimit = (temp == null) ? cSteady : (temp as Numeric).toFloat();
		try {
	        temp = Properties.getValue("Time");
		}
		catch (ex) {
			temp = null;
		}
		if (temp == null) {
			mTime = cTime;
		} else {
			try {
				temp = (temp as Numeric).toFloat();
			}
			catch (ex) {
				temp = null;
			}
		    mTime = (temp == null) ? cTime : (temp * -Gregorian.SECONDS_PER_HOUR - 10 * Gregorian.SECONDS_PER_MINUTE);
		}
		try {
	        temp = Properties.getValue("ShowTemp");
		}
		catch (ex) {
			temp = 1;
		}
       	mShowTemperature = (temp instanceof Number) ? (temp == 0) : cShowTemperature;
		if (mShowTemperature) {
			var temps =  Sensor.setEnabledSensors( [Sensor.SENSOR_TEMPERATURE] );
			if (temps.size() == 0) {
				mUseExternal = false;
			} else {
				mUseExternal = true;
				Sensor.enableSensorEvents( method(:onSensor) );
			}
		} else{
			Sensor.enableSensorEvents( null );
		}
		try {
	        temp = Properties.getValue("UseOriginal");
		}
		catch (ex) {
			temp = 1;
		}
       	mUseOriginal = (temp instanceof Number) ? (temp == 0) : false;

// default is 1 North, 0 South
		try {
	        temp = Properties.getValue("DefaultHemisphere");
		}
		catch (ex) {
			temp = 1;
		}
       	temp = ((temp instanceof Number) ? temp : 1); // Northern if not chosen correctly
		mDefHemi = temp>0 ? 1 : 0;
		mNorthSouth = mDefHemi;

		acquiringGPS = WatchUi.loadResource(Rez.Strings.GPS) as String;
	}

    function initialize() {
        View.initialize();

/*
        if (View has :setActionMenuIndicator) {
            setActionMenuIndicator({:enabled=>true});
        }
*/

		getSettings();
	}

	function onSensor(sensorInfo as Sensor.Info) as Void {
	    setSensorTemp(sensorInfo);
	}

	function compass(hd as Numeric or Null or String) as Number {
		if (hd instanceof Number || hd instanceof Long || hd instanceof Float || hd instanceof Double) {
			hd = Math.toDegrees(hd);
			hd = myMod((hd + 360 + 11.25), 360);
			return ((hd / 22.5) + 1).toNumber();
		} else {
			return 0;
		}
	}

	function getWindIndex() as Number {
        var tmp;
		try {
        	tmp = Storage.getValue("windIndex");
		}
		catch (ex) {
			tmp = null;
		}
        return (tmp == null) ? 0 : (tmp as Number);
	}

	function getWindDirection() as String {
        var tmp;
		try {
        	tmp = Storage.getValue("windDir");
		}
		catch (ex) {
			tmp = null;
		}
		if (tmp == null) {
			tmp = pString(0);
		}
        return tmp as String;
	}

	function setWindDirection(dir as Number) as Void {
		if (dir > 16) {
			dir = 0;
		}
        Storage.setValue("windDir", pString(dir));
        Storage.setValue("windIndex", dir);
    	mWind = getWindDirection();
		mDir = getWindIndex();
	}
	
	function setWindDirectionToCompass () as Void {
		var sensorInfo = Sensor.getInfo();
		setWindDirection(compass(sensorInfo.heading));
	}

    function onPosition(positionInfo as Position.Info) as Void {
		var location = [1, 0];
        if (positionInfo != null) {
            if (positionInfo.position != null) {
		   		location = (positionInfo.position as Position.Location).toDegrees();
		   	}
// A 2-D fix is good enough to tell us North or South
			if (positionInfo.accuracy >= Position.QUALITY_POOR) {
				enablePosition(false);
			}
		} else {
			location[0] = mDefHemi;
		}
		mNorthSouth = location[0]>0 ? 1 : 0;

        WatchUi.requestUpdate();
    }

	function enablePosition(acquire as Boolean) as Void {
		if (acquire) {
       	    var options = {
           	    :acquisitionType => Position.LOCATION_CONTINUOUS
               	};

            if (Position has :hasConfigurationSupport) {
   	            if ((Position has :CONFIGURATION_SAT_IQ) &&
       	          (Position.hasConfigurationSupport(Position.CONFIGURATION_SAT_IQ))) {
           	        options[:configuration] = Position.CONFIGURATION_SAT_IQ;
               	} else if ((Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5) &&
                   (Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5))) {
   	                options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5;
               	} else if ((Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1) &&
                   (Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1))) {
   	                options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1;
               	} else if ((Position has :CONFIGURATION_GPS_GLONASS) &&
                   (Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS))) {
   	                options[:configuration] = Position.CONFIGURATION_GPS_GLONASS;
               	} else if ((Position has :CONFIGURATION_GPS_GALILEO) &&
                   (Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GALILEO))) {
   	                options[:configuration] = Position.CONFIGURATION_GPS_GALILEO;
               	} else if ((Position has :CONFIGURATION_GPS_BEIDOU) &&
                   (Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_BEIDOU))) {
   	                options[:configuration] = Position.CONFIGURATION_GPS_BEIDOU;
               	} else if ((Position has :CONFIGURATION_GPS) &&
                   (Position.hasConfigurationSupport(Position.CONFIGURATION_GPS))) {
   	                options[:configuration] = Position.CONFIGURATION_GPS;
       	        }
           	} else if (Position has :CONSTELLATION_GLONASS) {
               	options[:constellations] = [ Position.CONSTELLATION_GPS, Position.CONSTELLATION_GLONASS ];
    	    } else if (Position has :CONSTELLATION_GALILEO) {
	            options[:constellations] = [ Position.CONSTELLATION_GPS, Position.CONSTELLATION_GALILEO ];
    	    } else if (Position has :CONSTELLATION_GPS) {
	            options[:constellations] = [ Position.CONSTELLATION_GPS ];
       	    } else {
           	    options = Position.LOCATION_CONTINUOUS;
           	}
            try {
   	            Position.enableLocationEvents(options, method(:onPosition));
       	    }
            catch (ex) {
   	            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
       	    }
		} else {
	       	Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
		}
        mAcquiringGPS = acquire;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        enablePosition(true);
    	mWind = getWindDirection();
    	mDir = getWindIndex();
    }

(:round_218)
	function getLayout(height as Number) as Array<Numeric> {
		return [7, 37, 64, 94, 126, 160, 192, 9];
	}

(:round_218_old)
	function getLayout(height as Number) as Array<Numeric> {
		return [2, 32, 59, 90, 124, 156, 186, 9];
	}

(:round_240)
	function getLayout(height as Number) as Array<Numeric> {
		return [5, 40, 68, 102, 137, 168, 200, 10];
	}

(:round_260)
	function getLayout(height as Number) as Array<Numeric> {
		return [5, 43, 78, 115, 150, 186, 224, 12];
	}

(:round_280)
	function getLayout(height as Number) as Array<Numeric> {
		return [10, 48, 86, 128, 169, 208, 248, 12];
	}

(:round_360)
	function getLayout(height as Number) as Array<Numeric> {
		return [8, 57, 103, 152, 204, 258, 310, 8];
	}

(:round_390)
	function getLayout(height as Number) as Array<Numeric> {
		return [10, 60, 108, 166, 225, 284, 337, 9];
	}

(:round_416)
	function getLayout(height as Number) as Array<Numeric> {
		return [10, 64, 115, 177, 241, 307, 362, 10];
	}

(:round_454)
	function getLayout(height as Number) as Array<Numeric> {
		return [10, 70, 126, 193, 263, 335, 395, 11];
	}

(:rectangle)
	function getLayout(height as Number) as Array<Numeric> {
		var num = height / 40.0;
		return [num*2, num*8, num*13, num*18, num*24, num*30, num*35, 0];
	}

// -----------------------------------------------------------------
	function setSensorTemp(sensorInfo as Sensor.Info) as Void
	{
		mSensorTemperature = getSensorTemperature(sensorInfo);
		if (mShowTemperature) {
			WatchUi.requestUpdate();
		}
	}

	function getSensorTemperature(sensorInfo as Sensor.Info) as String {
		var ret = "";
		var temperature = null;
// use tempe if possible
		if (sensorInfo != null && sensorInfo.temperature != null) {
			temperature = sensorInfo.temperature;
			Sensor.enableSensorEvents( null );
		}
		if (temperature != null) {
			var units = "°C";
			if (mNotMetricTemp) {
				temperature = (temperature * 9.0 / 5.0) + 32;
				units = "°F";
			}
    	    ret = temperature.format("%.0f") + units;// + " (tempe)";
    	}
    	return ret;
	}

	function getInternalTemperature() as String {
		var ret = "";
		var temperature = null;
// try to use internal via history
		var temperatureIter = getTemperatureIterator();
		if (temperatureIter != null) {
			var histTemp = temperatureIter.next();
			if (histTemp != null && histTemp.data != null) {
				temperature = histTemp.data;
			}
		}
		if (temperature != null) {
			var units = "°C";
			if (mNotMetricTemp) {
				temperature = (temperature * 9.0 / 5.0) + 32;
				units = "°F";
			}
    	    ret = temperature.format("%.0f") + units;
    	}
    	return ret;
	}

	function getTemperature() as String {
    	var temp = mSensorTemperature;
    	if (temp.equals("")) {
			temp = getInternalTemperature();
		}
		return temp;
	}

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        var thisTrend = "Steady";
		var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var mCentre = dc.getWidth() / 2;
		var samples = new Array<SensorSample>[0];
		var i = 0;

		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

		var layouts = getLayout(dc.getHeight());

		var pressureIter = getPressureIterator();
		var oldest = null;
		if (pressureIter != null) {
			var now = Time.now();
	    	var minus5Mins = new Time.Duration(-MINS_5);
			var minusTime = new Time.Duration(mTime.toNumber());
			var start = now.add(minusTime);
			oldest = pressureIter.getOldestSampleTime();
			if (oldest == null) { oldest = start; }
			else if ((start as Time.Moment).greaterThan(oldest as Time.Moment)) { oldest = start; }

	    	samples.add(pressureIter.next() as SensorHistory.SensorSample); i = 0;
    		while (samples[i].when.greaterThan(oldest)) {
			    var sampleNextTime = samples[i].when.add(minus5Mins);
	    		samples.add(pressureIter.next() as SensorHistory.SensorSample); i = samples.size() - 1;
    			while (samples[i].when.greaterThan(sampleNextTime) && samples[i].when.greaterThan(oldest)) {
    				samples[i] = pressureIter.next();
    			}
			}
		}
// Calculate the trend (0.5 hPa?) over e.g. 3 hours
		var final = samples.size() - 1;
		var s1 = 0;
		var s2 = 0;
		var p1 = 0;
		var p2 = 0;
		var cnt = 0;
		var t1, t2;
		if (final > 4) {
			for (i=0; i<3; i++) {
				t1 = false;
				if (samples[i].data != null) {
					s1 = samples[i].data;
					t1 = true;
				}
				t2 = false;
				if (samples[final - i].data != null) {
					s2 = samples[final - i].data;
					t2 = true;
				}
				if (t1 && t2) {
					p1 += (s1 as Number);
					p2 += (s2 as Number);
					cnt += 100;
				}
			}
		} else {
			for (i=0; i<final; i++) {
				if (samples[i].data != null) {
					p1 = samples[i].data;
					break;
				}
			}
			for (i=final; i>0; i--) {
				if (samples[i].data != null) {
					p2 = samples[i].data;
					break;
				}
			}
			cnt = 100;
		}
		var trend = 0;
		var pressureDiff = 0.0;
		try {
			if (cnt != 0) {
				pressureDiff = (p1 - p2) / cnt;
			}
		}
		catch (ex) {
			pressureDiff = 0.0;
		}
		if (pressureDiff < 0.0 && pressureDiff > -0.05) {
			pressureDiff = 0.0;
		}
		if (pressureDiff > mSteadyLimit) {
	    	trend = 1;
		}
		else if ((pressureDiff+mSteadyLimit) < 0) {
   			trend = 2;
   		}
    	Storage.setValue("trend", trend);

// Get the current pressure
		var currentPress = 0;
		if (mUseMSLPressure) {
			if (mUseOriginal) {
				var activityInfo = Activity.getActivityInfo();
				if (activityInfo != null && activityInfo has :meanSeaLevelPressure && activityInfo.meanSeaLevelPressure != null) {
					currentPress = activityInfo.meanSeaLevelPressure;
				}
			} else {
				for (i=0; i<final; i++) {
					if (samples[i].data != null) {
						currentPress = samples[i].data;
						break;
					}
				}
			}
		} else {
			var activityInfo = Activity.getActivityInfo();
			if (activityInfo != null && activityInfo has :ambientPressure && activityInfo.ambientPressure != null) {
				currentPress = activityInfo.ambientPressure;
			}
		}
		currentPress = mOffset + Math.round(currentPress as Float / 100.0).toNumber();
// Use the stored wind direction
    	dc.drawText(mCentre, layouts[0], Graphics.FONT_LARGE, mWind, Graphics.TEXT_JUSTIFY_CENTER);
    	dc.drawText(mCentre, layouts[1], Graphics.FONT_MEDIUM, currentPress.toString()+" hPa", Graphics.TEXT_JUSTIFY_CENTER);

		thisTrend = tString(trend);
    	dc.drawText(mCentre, layouts[2], Graphics.FONT_MEDIUM, thisTrend + " ("+(pressureDiff).format("%.1f")+")", Graphics.TEXT_JUSTIFY_CENTER);

//function betel_cast(hpa,    month,    wind, trend, hemisphere,     upper, lower)
		var val = Zambretti.betel_cast(currentPress, today.month as Number, mDir, trend, mNorthSouth, mHighPressure, mLowPressure);
    	Storage.setValue("forecast", val[0] as String);

		var sw2 = mCentre - layouts[7]; // half the screen width less a fudge factor

		var f;
		for (f = Graphics.FONT_LARGE; f>=Graphics.FONT_XTINY; f--) {
			var tw = dc.getTextDimensions(val[0] as String, f)[0]/2;
			if (tw < sw2) {break;}
		}
    	dc.drawText(mCentre, layouts[3], f as Graphics.FontDefinition, val[0] as String, Graphics.TEXT_JUSTIFY_CENTER);

		for (; f>=Graphics.FONT_XTINY; f--) {
			var tw = dc.getTextDimensions(val[1] as String, f as Graphics.FontDefinition)[0]/2;
			if (tw < sw2) {
				break;
			}
		}
    	dc.drawText(mCentre, layouts[4], f as Graphics.FontDefinition, val[1] as String, Graphics.TEXT_JUSTIFY_CENTER);

		if (mShowTemperature) {
			var temp = getTemperature();
			if (!temp.equals("")) {
				dc.drawText(mCentre, layouts[5], Graphics.FONT_MEDIUM, temp, Graphics.TEXT_JUSTIFY_CENTER);
			}
    	}
    	dc.drawText(mCentre, layouts[6], Graphics.FONT_XTINY, mAcquiringGPS ? acquiringGPS : "", Graphics.TEXT_JUSTIFY_CENTER);
    }

	function myMod(a as Numeric, b as Numeric) as Numeric {
		var d = (b < 0) ? -b : b;
		var m = (a - ((a / d).toLong() * d));
		var r = ((m < 0) ? (d + m) : m);
		return ((b < 0) ? (r + b) : r);
	}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        enablePosition(false);
    }
    
// Create a method to get the SensorHistoryIterator object
	function getPressureIterator() as SensorHistory.SensorHistoryIterator or Null {
    // Check device for SensorHistory compatibility
    	if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getPressureHistory)) {
        	return SensorHistory.getPressureHistory({:order => SensorHistory.ORDER_NEWEST_FIRST});
    	}
    	return null;
	}

	function getTemperatureIterator() as SensorHistory.SensorHistoryIterator or Null {
    // Check device for SensorHistory compatibility
    	if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
        	return SensorHistory.getTemperatureHistory({:order => SensorHistory.ORDER_NEWEST_FIRST});
    	}

    	return null;
	}
}

(:glance)
class SimplyWeatherGlanceView extends WatchUi.GlanceView {
	var titleY as Number = 30;
	var valueY as Number = 60;

	function initialize() {
		GlanceView.initialize();
	}

	function getTitle() as String {
		var AppTitle = Properties.getValue("AppTitle");
		if (AppTitle == null ) {
			AppTitle = WatchUi.loadResource( Rez.Strings.AppName );
		}
		return AppTitle as String;
	}

	function onLayout(dc as Dc) as Void {
		var dHeight = dc.getHeight();
		var tHeight = dc.getFontHeight(Graphics.FONT_GLANCE); //SMALL);
		var vHeight = dc.getFontHeight(Graphics.FONT_GLANCE); //TINY);
		titleY = (dHeight - tHeight - vHeight) / 2;
		if ((tHeight + vHeight) > dHeight) {
			titleY -= 2;
		}
		valueY = titleY + tHeight;
	}

    function onUpdate(dc as Dc) as Void {
		var fc = "";

		dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
		dc.clear();
		dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);

		try {
	    	fc = Storage.getValue("forecast");
		}
		catch (ex) {
			fc = null;
		}
    	if (fc == null) { fc = ""; }

		dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
		dc.drawText(0, valueY, Graphics.FONT_GLANCE, fc, Graphics.TEXT_JUSTIFY_LEFT); //TINY

		var AppTitle = getTitle();
		var fnt = Graphics.FONT_GLANCE;

		dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
		dc.drawText(0, titleY, fnt, AppTitle, Graphics.TEXT_JUSTIFY_LEFT);
	}

}
