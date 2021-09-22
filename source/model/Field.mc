class Field {
	enum {
		COMPARTMENT_TOP_LEFT, 
		COMPARTMENT_TOP_RIGHT, 
		COMPARTMENT_BOTTOM_RIGHT, 
		COMPARTMENT_BOTTOM_LEFT,
		COMPARTMENT_TOP_CENTER,
		COMPARTMENT_BOTTOM_CENTER
	}

	enum {
		TYPE_NONE, 
		TYPE_TIME_TO_EVENT, 
		TYPE_BATTERY
	}

	private var value;
	
	function initialize(value) {
		self.value = value;
	}
	
	function getValue() {
		return value;
	}
}
