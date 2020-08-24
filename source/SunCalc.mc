using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Position as Pos;

// A modified version of SunCalc borrowed from https://github.com/haraldh/SunCalc
class SunCalc {

	class Moment {
		enum { ABOVE_HORIZONT, BELOW_HORIZONT }
	}

	enum {
	    ASTRO_DAWN,
	    NAUTIC_DAWN,
	    DAWN,
	    BLUE_HOUR_AM,
	    SUNRISE,
	    SUNRISE_END,
	    GOLDEN_HOUR_AM,
	    NOON,
	    GOLDEN_HOUR_PM,
	    SUNSET_START,
	    SUNSET,
	    BLUE_HOUR_PM,
	    DUSK,
	    NAUTIC_DUSK,
	    ASTRO_DUSK
	}

    private const PI = Math.PI,
        RAD = Math.PI / 180.0,
        PI2 = Math.PI * 2.0,
        J1970 = 2440588,
        J2000 = 2451545,
        J0 = 0.0009;

    private const TIMES = [
        -18 * RAD,    // ASTRO_DAWN
        -12 * RAD,    // NAUTIC_DAWN
        -6 * RAD,     // DAWN
        -4 * RAD,     // BLUE_HOUR
        -0.833 * RAD, // SUNRISE
        -0.3 * RAD,   // SUNRISE_END
        6 * RAD,      // GOLDEN_HOUR_AM
        0,         	  // NOON
        6 * RAD,
        -0.3 * RAD,
        -0.833 * RAD,
        -4 * RAD,
        -6 * RAD,
        -12 * RAD,
        -18 * RAD
    ];

    var	n, ds, M, sinM, C, L, sin2L, dec, Jnoon;

    function julianToMoment(j) {
        return new Time.Moment((j + 0.5 - J1970) * Time.Gregorian.SECONDS_PER_DAY);
    }

    function round(a) {
        if (a > 0) {
            return (a + 0.5).toNumber().toFloat();
        } else {
            return (a - 0.5).toNumber().toFloat();
        }
    }

    // lat and lng in radians
    function calculate(moment, lat, lng, what) {
        var d = moment.value().toDouble() / Time.Gregorian.SECONDS_PER_DAY + J1970 - J2000;
        n = round(d - J0 + lng / PI2);
//			ds = J0 - lng / PI2 + n;
        ds = J0 - lng / PI2 + n - 1.1574e-5 * 68;
        M = 6.240059967 + 0.0172019715 * ds;
        sinM = Math.sin(M);
        C = (1.9148 * sinM + 0.02 * Math.sin(2 * M) + 0.0003 * Math.sin(3 * M)) * RAD;
        L = M + C + 1.796593063 + PI;
        sin2L = Math.sin(2 * L);
        dec = Math.asin( 0.397783703 * Math.sin(L) );
        
        Jnoon = J2000 + ds + 0.0053 * sinM - 0.0069 * sin2L;
        if (what == NOON) {
            return julianToMoment(Jnoon);
        }

        var x = (Math.sin(TIMES[what]) - Math.sin(lat) * Math.sin(dec)) / (Math.cos(lat) * Math.cos(dec));
        if (x > 1.0) {
        	return Moment.BELOW_HORIZONT;
        } else if (x < -1.0) {
        	return Moment.ABOVE_HORIZONT;
        }

        var ds = J0 + (Math.acos(x) - lng) / PI2 + n - 1.1574e-5 * 68;
        var Jset = J2000 + ds + 0.0053 * sinM - 0.0069 * sin2L;
        if (what > NOON) {
            return julianToMoment(Jset);
        }

        var Jrise = Jnoon - (Jset - Jnoon);
        return julianToMoment(Jrise);
    }

    static function printMoment(moment) {
    	if (moment == null) {
    		return null;
    	}
        var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.day.format("%02d") + "." + info.month.format("%02d") + "." + info.year.toString() + " " + 
        	info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" + info.sec.format("%02d");
    }

    (:test) static function testCalc(logger) {

        var testMatrix = [
            [ 1496310905, 48.1009616, 11.759784, NOON, 1496315468 ],
            [ 1496310905, 70.6632359, 23.681726, NOON, 1496312606 ],
            [ 1496310905, 70.6632359, 23.681726, SUNSET, null ],
            [ 1496310905, 70.6632359, 23.681726, SUNRISE, null ],
            [ 1496310905, 70.6632359, 23.681726, ASTRO_DAWN, null ],
            [ 1496310905, 70.6632359, 23.681726, NAUTIC_DAWN, null ],
            [ 1496310905, 70.6632359, 23.681726, DAWN, null ],
            [ 1483225200, 70.6632359, 23.681726, SUNRISE, null ],
            [ 1483225200, 70.6632359, 23.681726, NOON, 1483266532 ],
            [ 1483225200, 70.6632359, 23.681726, ASTRO_DAWN, 1483247635 ],
            [ 1483225200, 70.6632359, 23.681726, NAUTIC_DAWN, 1483252565 ],
            [ 1483225200, 70.6632359, 23.681726, DAWN, 1483259336 ]
            ];

        var sc = new SunCalc();
        var moment;

        for (var i = 0; i < testMatrix.size(); i++) {
            moment = sc.calculate(new Time.Moment(testMatrix[i][0]),
                                  new Pos.Location(
                                      { :latitude => testMatrix[i][1], :longitude => testMatrix[i][2], :format => :degrees }
                                      ).toRadians(),
                                  testMatrix[i][3]);

            if (   (moment == null  && testMatrix[i][4] != moment)
                   || (moment != null && moment.value().toLong() != testMatrix[i][4])) {
                var val;

                if (moment == null) {
                    val = "null";
                } else {
                    val = moment.value().toLong();
                }

                logger.debug("Expected " + testMatrix[i][4] + " but got: " + val);
                logger.debug(printMoment(moment));
                return false;
            }
        }

        return true;
    }
}
