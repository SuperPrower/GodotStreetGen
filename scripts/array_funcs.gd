extends Object

func array_slice(array, bottom, top):
	var out = []
	for c in range(bottom, top):
		out.append(array[c])
	return out

func array_sum(array):
	var sum = 0
	for i in array:
		sum += i
	return sum
	
func array_max(array):
	var max_val = array[0]
	for i in array:
		max_val = max(max_val, i)
		
	return max_val