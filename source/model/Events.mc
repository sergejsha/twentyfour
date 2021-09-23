class Events {
	private var events;
	private var sec, lat, lng;
	private var text1;
	private var text2;

	function initialize(events, sec, lat, lng, text1, text2) {
		self.events = events;
		self.sec = sec;
		self.lat = lat;
		self.lng = lng;
		self.text1 = text1;
		self.text2 = text2;
	}
	
	function getText1() {
		return text1;
	}
	
	function getText2() {
		return text2;
	}
	
	function get(index) {
		return events[index];
	}
	
	function size() {
		if (events == null) {
			return 0;
		} else {
			return events.size();
		}
	}
	
	function isUpdateReqiured(now, lat, lng) {
		return (now.value() - self.sec).abs() > 60 || self.lat != lat || self.lng != lng;
	}
}