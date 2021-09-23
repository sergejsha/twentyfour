class List {
	
	private var items;
	private var _size;
	
	function initialize(capacity) {
		items = new [capacity];
		_size = 0;
	}
	
	function size() {
		return _size;
	}
	
	function get(index) {
		return items[index];
	}
	
	function add(item) {
		incrementSize();
		items[_size - 1] = item;
	}
	
	function toArray() {
		var array = new [_size];
		for(var i = 0; i < _size; i++) {
			array[i] = items[i];
		}
		return array;
	}
	
	private function incrementSize() {
		_size += 1;
		if (_size > items.size()) {
			var newItems = new [items.size() * 2];
			for (var i = 0; i < items.size(); i++) {
				newItems[i] = items[i];
			}
			items = newItems;
		}
	}
}
