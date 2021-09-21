using Toybox.Math;
using Toybox.Time;

//
// Monkenized from https://github.com/mourner/suncalc/blob/master/suncalc.js
//
class SunCalc {

	// shortcuts 
	
	private static const rad = Math.PI.toDouble() / 180;
	
	// sun calculations are based on http://aa.quae.nl/en/reken/zonpositie.html formulas
	
	// date/time constants and conversions
	
	private static const daySec = Time.Gregorian.SECONDS_PER_DAY;
    private static const J1970 = 2440588;
    private static const J2000 = 2451545;

	private static function toJulian(moment) {
		return moment.value().toDouble() / daySec + J1970;
	}
	
	private static function fromJulian(j) {
		return new Time.Moment(((j + 0.5 - J1970) * daySec).toNumber());
	}
	
	private static function toDays(moment) { 
		return toJulian(moment) - J2000;
	}
	
	// general calculations for position
	
	private static const e = rad * 23.4397;
	
	private static function rightAscension(l, b) { 
		return Math.atan2(Math.sin(l) * Math.cos(e) - Math.tan(b) * Math.sin(e), Math.cos(l)); 
	}
	
	private static function declination(l, b) { 
		return Math.asin(Math.sin(b) * Math.cos(e) + Math.cos(b) * Math.sin(e) * Math.sin(l)); 
	}
	
	private static function _azimuth(H, phi, dec) { 
		return Math.atan(Math.sin(H), Math.cos(H) * Math.sin(phi) - Math.tan(dec) * Math.cos(phi)); 
	}
	
	private static function _altitude(H, phi, dec) { 
		return Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(H));
	}
	
	private static function siderealTime(d, lw) { 
		return rad * (280.16.toDouble() + 360.9856235 * d) - lw;
	}
	
	private static function astroRefraction(h) {
	    if (h < 0) { // the following formula works for positive altitudes only.
	    	h = 0; // if h = -0.08901179 a div/0 would occur.
	    } 

	    // formula 16.4 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
    	// 1.02 / tan(h + 10.26 / (h + 5.10)) h in degrees, result in arc minutes -> converted to rad:
    	return 0.0002967 / Math.tan(h + 0.00312536 / (h + 0.08901179));
	}
	
	// general sun calculations
	
	private static function solarMeanAnomaly(d) { 
		return rad * (357.5291 + 0.98560028 * d); 
	}
	
	private static function eclipticLongitude(M) {
    	var C = rad * (1.9148 * Math.sin(M) + 0.02 * Math.sin(2 * M) + 0.0003 * Math.sin(3 * M)); // equation of center
        var P = rad * 102.9372; // perihelion of the Earth
    	return M + C + P + Math.PI;
	}
	
	private static function sunCoords(d) {
	    var M = solarMeanAnomaly(d);
	    var L = eclipticLongitude(M);
	    return {
	        :dec => declination(L, 0),
	        :ra => rightAscension(L, 0)
	    };
	}
	
	// calculates sun position for a given date and latitude/longitude
	
	static function getPosition(moment, lat, lng) {
	    var lw  = rad * (-lng);
	    var phi = rad * lat;
	    var d   = toDays(moment);
	    var c   = sunCoords(d);
	    var H   = siderealTime(d, lw) - c[:ra];
	
	    return {
	        :azimuth => _azimuth(H, phi, c[:dec]),
	        :altitude => _altitude(H, phi, c[:dec])
	    };
    }
    
	// calculations for sun times
	
	private static const J0 = 0.0009;
	
	private static function julianCycle(d, lw) { 
		return Math.round(d - J0 - lw / (2 * Math.PI)); 
	}
	
	private static function approxTransit(Ht, lw, n) { 
		return J0 + (Ht + lw) / (2 * Math.PI) + n; 
	}
	
	private static function solarTransitJ(ds, M, L)  { 
		var add = 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
		var dsAdd = ds.toDouble() + add.toDouble();
		return J2000 + ds + add;
	}
	
	private static function hourAngle(h, phi, d) {
		return Math.acos((Math.sin(h) - Math.sin(phi) * Math.sin(d)) / (Math.cos(phi) * Math.cos(d)));
	}
	
	private static function observerAngle(height) {
		return -2.076.toDouble() * Math.sqrt(height) / 60; 
	}
	
	// returns set time for the given sun altitude
	private static function getSetJ(h, lw, phi, dec, n, M, L) {
	    var w = hourAngle(h, phi, dec);
	    var a = approxTransit(w, lw, n);
	    return solarTransitJ(a, M, L);
	}
	
    // sun times configuration (angle, morning name, evening name)

	private static const times = [
	    [-0.833, :sunrise, :sunset ],
	    //[  -0.3, :sunriseEnd, :sunsetStart ],
	    //[    -6, :dawn, :dusk ],
	    //[   -12, :nauticalDawn, :nauticalDusk ],
	    //[   -18, :nightEnd, :night ],
	    //[     6, :goldenHourEnd, :goldenHour ]
	];
	
	// calculates sun times for a given date, latitude/longitude, and, optionally,
	// the observer height (in meters) relative to the horizon

	function getTimes(moment, lat, lng, height) {

	    var lw = rad * (-lng);
	    var phi = rad * lat;
        var dh = observerAngle(height);
	
	    var d = toDays(moment);
	    var n = julianCycle(d, lw);
	    var ds = approxTransit(0, lw, n);
	
	    var M = solarMeanAnomaly(ds);
	    var L = eclipticLongitude(M);
	    var dec = declination(L, 0);
	
	    var Jnoon = solarTransitJ(ds, M, L);
	    var time, h0, Jset, Jrise;
	
	    var result = {
	        :solarNoon => fromJulian(Jnoon),
	        :nadir => fromJulian(Jnoon - 0.5)
	    };
	
	    for (var i = 0; i < times.size(); i++) {
	        time = times[i];
	        h0 = (time[0] + dh) * rad;
	        
	        Jset = getSetJ(h0, lw, phi, dec, n, M, L);
	        Jrise = Jnoon - (Jset - Jnoon);
	
	        result[time[1]] = fromJulian(Jrise);
	        result[time[2]] = fromJulian(Jset);
	    }
	
	    return result;
	}	

	(:test)
	static function createMoments(log) {
	
		var lat = 49.458914, lng = 8.563376;
		var today = new Time.Moment(1598911200);
		
		var sunCalc = new SunCalc();
		var times = sunCalc.getTimes(today, lat, lng, 0);
		
		log.debug("today: " + SunCalc.printMoment(today));
		log.debug("sunrise: " + SunCalc.printMoment(times[:sunrise]));
		log.debug("solar noon: " + SunCalc.printMoment(times[:solarNoon]));
		log.debug("sunset: " + SunCalc.printMoment(times[:sunset]));
	
		return true;
	}
	
}

// DEBUG (18:31): sunrise: 01.09.2020 06:43:24
// DEBUG (18:31): solar noon: 01.09.2020 13:27:11
// DEBUG (18:31): sunset: 01.09.2020 20:10:59

// DEBUG (18:28): sunrise: 02.09.2020 06:44:51
// DEBUG (18:28): solar noon: 02.09.2020 13:26:52
// DEBUG (18:28): sunset: 02.09.2020 20:08:53

