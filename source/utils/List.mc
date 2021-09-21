using Toybox.Lang;

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
		_size++;
		if (_size > items.size()) {
			var newItems = new [items.size() * 2];
			for (var i = 0; i < items.size(); i++) {
				newItems[i] = items[i];
			}
			items = newItems;
		}
		items[_size - 1] = item;
	}
	
	function sort(comparator) {
		quickSort(items, 0, _size - 1, comparator);
	}
	
	private static function quickSort(items, low, high, comparator) {
	    if (low < high) {
	        var pi = partition(items, low, high, comparator);
	        quickSort(items, low, pi - 1, comparator);
	        quickSort(items, pi + 1, high, comparator);
	    }	
	}
	
	private static function partition(items, low, high, comparator) {
	    var pivot = items[high];  
	    var i = low - 1;
	
	    for (var j = low; j <= high - 1; j++) {
	    	var item = items[j];
	    	if (comparator.invoke(pivot, item) > 0) { 
	            i++;
	            swap(items, i, j);
	        }
	    }
	    
	    swap(items, i + 1, high);
	    return i + 1;
	}
	
	private static function swap(items, i, j) {
		var item = items[i];
		items[i] = items[j];
		items[j] = item;
	}
}

(:debug)
class ListTest {

	(:test)
	static function sort(log) {
		
		var list = new List(2);
		list.add(3);
		list.add(1);
		list.add(0);
		list.add(5);
		list.add(4);
		list.add(2);
		
		var callback = new ListTest();
		list.sort(callback.method(:asc));
		
		var expected = [0, 1, 2, 3, 4, 5];
		
		for (var i = 0; i < list.size(); i++) {
			var actualItem = list.get(i);
			var expectedItem = expected[i];
			if (actualItem != expectedItem) {
				log.error(
					"Actual: " + actualItem + 
					", while expecting: " + expectedItem + 
					" at position: " + i
				);
				return false;
			}
		}
		
		return true;
	}
	
	function asc(v1, v2) {
		return v1 - v2;
	}
}