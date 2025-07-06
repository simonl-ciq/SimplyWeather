// beteljuice.com - near enough Zambretti Algorhithm 
// June 2008 - v1.0
// tweak added so decision # can be output

/* Negretti and Zambras 'slide rule' is supposed to be better than 90% accurate 
for a local forecast upto 12 hrs, it is most accurate in the temperate zones and about 09:00  hrs local solar time.
I hope I have been able to 'tweak it' a little better ;-)	

This code is free to use and redistribute as long as NO CHARGE is EVER made for its use or output
*/

import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Zambretti {

// ---- 'environment' variables ------------  NOT USED LIKE THIS
/*
var z_where = 1;  // Northern = 1 or Southern = 2 hemisphere
var z_baro_top = 1050;	// upper limits of your local 'weather window' (1050.0 hPa for UK)
var z_baro_bottom = 950;	// lower limits of your local 'weather window' (950.0 hPa for UK)
*/

// usage:   forecast = betel_cast( z_hpa, z_month, z_wind, z_trend [, z_where] [, z_baro_top] [, z_baro_bottom])[0];

// z_hpa is Sea Level Adjusted (Relative) barometer in hPa or mB
// z_month is current month as a number between 1 to 12
// z_wind is English windrose cardinal eg. N, NNW, NW etc.
// NB. if calm a 'nonsense' value should be sent as z_wind (direction) eg. 1 or calm !
// z_trend is barometer trend: 0 = no change, 1= rise, 2 = fall
// z_where - OPTIONAL for posting with form
// z_baro_top - OPTIONAL for posting with form
// z_baro_bottom - OPTIONAL for posting with form
// [0] a short forecast text is returned
// [1] zambretti severity number (0 - 25) is returned ie. betel_cast() returns a two deep array

//var z_forecast = ["Settled fine", "Fine weather", "Becoming fine", "Fine, becoming less settled", "Fine, possible showers", "Fairly fine, improving", "Fairly fine, possible showers early", "Fairly fine, showery later", "Showery early, improving", "Changeable, mending", "Fairly fine, showers likely", "Rather unsettled, clearing later", "Unsettled, probably improving", "Showery, bright intervals", "Showery, becoming less settled", "Changeable, some rain", "Unsettled, short fine intervals", "Unsettled, rain later", "Unsettled, some rain", "Mostly very unsettled", "Occasional rain, worsening", "Rain at times, very unsettled", "Rain at frequent intervals", "Rain, very unsettled", "Stormy, may improve", "Stormy, much rain"]; 
/*
var z_forecast0 as Array<String> = ["Settled fine", "Fine weather", "Becoming fine", "Fine"                 , "Fine"             , "Fairly fine", "Fairly fine"           , "Fairly fine"  , "Showery early", "Changeable", "Fairly fine"   , "Rather unsettled", "Unsettled"         , "Showery"         , "Showery"              , "Changeable", "Unsettled"           , "Unsettled" , "Unsettled", "Very unsettled", "Occasional rain", "Rain at times", "Rain"                  , "Rain"          , "Stormy"     , "Stormy"   ]; 
var z_forecast1 as Array<String> = [""            , ""            , ""             , "becoming less settled", "possible showers" , "improving"  , "possible showers early", "showery later", "improving"    , "mending"   , "showers likely", "clearing later"  , "probably improving", "bright intervals", "becoming less settled", "some rain" , "short fine intervals", "rain later", "some rain", "(mostly)"      , "worsening"      , "very unsettled", "at frequent intervals", "very unsettled", "may improve", "much rain"]; 
*/
var forecastStrings0 as Array<Lang.ResourceId> = [
	Rez.Strings.SF,
	Rez.Strings.FW,
	Rez.Strings.BF,
	Rez.Strings.FN,
	Rez.Strings.FN,
	Rez.Strings.FF,
	Rez.Strings.FF,
	Rez.Strings.FF,
	Rez.Strings.SHE,
	Rez.Strings.CH,
	Rez.Strings.FF,
	Rez.Strings.RU,
	Rez.Strings.UN,
	Rez.Strings.SH,
	Rez.Strings.SH,
	Rez.Strings.CH,
	Rez.Strings.UN,
	Rez.Strings.UN,
	Rez.Strings.UN,
	Rez.Strings.VU,
	Rez.Strings.OR,
	Rez.Strings.RT,
	Rez.Strings.RA,
	Rez.Strings.RA,
	Rez.Strings.ST,
	Rez.Strings.ST
];

var forecastStrings1 as Array<Lang.ResourceId> = [
	Rez.Strings.MT,
	Rez.Strings.MT,
	Rez.Strings.MT,
	Rez.Strings.LS,
	Rez.Strings.PS,
	Rez.Strings.IM,
	Rez.Strings.PSE,
	Rez.Strings.SL,
	Rez.Strings.IM,
	Rez.Strings.ME,
	Rez.Strings.SY,
	Rez.Strings.CL,
	Rez.Strings.PI,
	Rez.Strings.BI,
	Rez.Strings.LS,
	Rez.Strings.SR,
	Rez.Strings.SI,
	Rez.Strings.RL,
	Rez.Strings.SR,
	Rez.Strings.MO,
	Rez.Strings.WO,
	Rez.Strings.VU,
	Rez.Strings.FI,
	Rez.Strings.VU,
	Rez.Strings.MI,
	Rez.Strings.MR
] as Array<Lang.ResourceId>;

// equivalents of Zambretti 'dial window' letters A - Z
var rise_options as Array<Number> = [25,25,25,24,24,19,16,12,11,9,8,6,5,2,1,1,0,0,0,0,0,0];
var steady_options as Array<Number> = [25,25,25,25,25,25,23,23,22,18,15,13,10,4,1,1,0,0,0,0,0,0]; 
var fall_options as Array<Number> = [25,25,25,25,25,25,25,25,23,23,21,20,17,14,7,3,1,1,1,0,0,0];

	function forecast0(f as Number) as String {
			return WatchUi.loadResource((forecastStrings0 as Array<Lang.ResourceId>)[f]) as String;
	}

	function forecast1(f as Number) as String {
			return WatchUi.loadResource((forecastStrings1 as Array<Lang.ResourceId>)[f]) as String;
	}

// ---- MAIN FUNCTION --------------------------------------------------
//function betel_cast(z_hpa as Float or Number, z_month as Number, z_wind as String, z_trend as Number, z_where as Number, z_baro_top as Float or Number, z_baro_bottom as Float or Number) as Array {
  function betel_cast(z_hpa as Float or Number, z_month as Number, z_wind_dir as Number, z_trend as Number, z_where as Number, z_baro_top as Float or Number, z_baro_bottom as Float or Number) as Array {
/*
z_hpa = z_hpa;	
z_hpa = 980; z_month = 5; z_wind = "E"; z_trend = 0;
z_where = 1; z_baro_top = 1010; z_baro_bottom = 990;
*/
	var z_frac = (z_baro_top - z_baro_bottom) / 100.0;
	var z_constant = z_frac * 4.5454545454; // 100 / 22;
	var z_season = (z_month >= 4 && z_month <= 9) ; 	// true if 'Summer'

try {
	if (z_where == 1) {  		// North hemisphere
		if (z_wind_dir == 1) { // && z_wind.equals("N")) {
			z_hpa += (6 * z_frac) ;
		} else if (z_wind_dir == 2) { // && z_wind.equals("NNE")) {  
			z_hpa += (5 * z_frac) ;  
		} else if (z_wind_dir == 3) { // && z_wind.equals("NE")) {  
//			z_hpa += (4 ;  
			z_hpa += (5 * z_frac) ;  
		} else if (z_wind_dir == 4) { // && z_wind.equals("ENE")) {  
			z_hpa += (2 * z_frac) ;  
		} else if (z_wind_dir == 5) { // && z_wind.equals("E")) {  
			z_hpa -= (0.5 * z_frac) ;  
		} else if (z_wind_dir == 6) { // && z_wind.equals("ESE")) {  
//			z_hpa -= 3 ;  
			z_hpa -= (2 * z_frac) ;  
		} else if (z_wind_dir == 7) { // && z_wind.equals("SE")) {  
			z_hpa -= (5 * z_frac) ;  
		} else if (z_wind_dir == 8) { // && z_wind.equals("SSE")) {  
			z_hpa -= (8.5 * z_frac) ;  
		} else if (z_wind_dir == 9) { // && z_wind.equals("S")) {  
//			z_hpa -= (11 ;  
			z_hpa -= (12 * z_frac) ;  
		} else if (z_wind_dir == 10) { // && z_wind.equals("SSW")) {  
			z_hpa -= (10 * z_frac) ;  //
		} else if (z_wind_dir == 11) { // && z_wind.equals("SW")) {  
			z_hpa -= (6 * z_frac) ;  
		} else if (z_wind_dir == 12) { // && z_wind.equals("WSW")) {  
			z_hpa -= (4.5 * z_frac) ;  //
		} else if (z_wind_dir == 13) { // && z_wind.equals("W")) {  
			z_hpa -= (3 * z_frac);  
		} else if (z_wind_dir == 14) { // && z_wind.equals("WNW")) {  
			z_hpa -= (0.5 * z_frac) ;  
		}else if (z_wind_dir == 15) { // && z_wind.equals("NW")) {  
			z_hpa += (1.5 * z_frac) ;  
		} else if (z_wind_dir == 16) { // && z_wind.equals("NNW")) {  
			z_hpa += (3 * z_frac) ;  
		}
		if (z_season) {  	// if Summer
			if (z_trend == 1) {  	// rising
				z_hpa += (7 * z_frac) ;  
			} else if (z_trend == 2) {  //	falling
				z_hpa -= (7 * z_frac) ; 
			} 
		} 
	} else {  	// must be South hemisphere
		if (z_wind_dir == 9) { // && z_wind.equals("S")) {  
			z_hpa += (6 * z_frac) ;  
		} else if (z_wind_dir == 10) { // && z_wind.equals("SSW")) {  
			z_hpa += (5 * z_frac) ;  
		} else if (z_wind_dir == 11) { // && z_wind.equals("SW")) {  
//			z_hpa += (4 ;  
			z_hpa += (5 * z_frac) ;  
		} else if (z_wind_dir == 12) { // && z_wind.equals("WSW")) {  
			z_hpa += (2 * z_frac) ;  
		} else if (z_wind_dir == 13) { // && z_wind.equals("W")) {  
			z_hpa -= (0.5 * z_frac) ;  
		} else if (z_wind_dir == 14) { // && z_wind.equals("WNW")) {  
//			z_hpa -= 3 ;  
			z_hpa -= (2 * z_frac) ;  
		} else if (z_wind_dir == 15) { // && z_wind.equals("NW")) {  
			z_hpa -= (5 * z_frac) ;  
		} else if (z_wind_dir == 16) { // && z_wind.equals("NNW")) {  
			z_hpa -= (8.5 * z_frac) ;  
		} else if (z_wind_dir == 1) { // && z_wind.equals("N")) {  
//			z_hpa -= 11 ;  
			z_hpa -= (12 * z_frac) ;  
		} else if (z_wind_dir == 2) { // && z_wind.equals("NNE")) {  
			z_hpa -= (10 * z_frac) ;  //
		} else if (z_wind_dir == 3) { // && z_wind.equals("NE")) {  
			z_hpa -= (6 * z_frac) ;  
		} else if (z_wind_dir == 4) { // && z_wind.equals("ENE")) {  
			z_hpa -= (4.5 * z_frac) ;  //
		} else if (z_wind_dir == 5) { // && z_wind.equals("E")) {  
			z_hpa -= (3 * z_frac) ;  
		} else if (z_wind_dir == 6) { // && z_wind.equals("ESE")) {  
			z_hpa -= (0.5 * z_frac) ;  
		}else if (z_wind_dir == 7) { // && z_wind.equals("SE")) {  
			z_hpa += (1.5 * z_frac) ;  
		} else if (z_wind_dir == 8) { // && z_wind.equals("SSE")) {  
			z_hpa += (3 * z_frac) ;  
		}
		if (!z_season) { 	// if Winter
			if (z_trend == 1) {  // rising
				z_hpa += (7 * z_frac) ;
			} else if (z_trend == 2) {  // falling
				z_hpa -= (7 * z_frac) ;
			} 
		} 
	} 	// END North / South
}
catch ( ex ) {
	z_hpa = 0.0;
}

	z_hpa = z_hpa.toNumber();
	if(z_hpa == z_baro_top) {z_hpa = z_baro_top - 1;}
	var z_except = false;
	var z_option = Math.floor((z_hpa - z_baro_bottom) / z_constant).toNumber();
 	var z_output0 = "";
 	var z_output1 = "";
	if(z_option < 0) {
		z_option = 0;
		z_except = true;
		z_output0 = "*";
		z_output1 = "*";
	}
	else if(z_option > 21) {
		z_option = 21;
		z_except = true;
		z_output0 = "*";
		z_output1 = "*";
	}

/*
	var siz = steady_options.size();
	siz = z_forecast0.size();
*/
	var forecast = 0;
	if (z_trend == 1) { 	// rising
		forecast = rise_options[z_option];
	} else if (z_trend == 2) { 	// falling
		forecast = fall_options[z_option];
	} else { 	// must be 'steady'
		forecast = steady_options[z_option];
	}
/*
	z_output0 += z_forecast0[forecast] ;
	z_output1 += z_forecast1[forecast] ;
*/
	z_output0 += forecast0(forecast);
	z_output1 += forecast1(forecast);
	if (z_except) {
		z_output0 += "*";
		if (z_output1.equals("*")) {z_output1 = "";}
		else {z_output1 += "*";}
	}
	return [z_output0, z_output1, forecast]; 
}	// END function

}
