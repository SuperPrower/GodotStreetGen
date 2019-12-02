extends Object

# imports
var array_func = load("res://scripts/array_funcs.gd")
var af = array_func.new()
	
func leftoverrow(sizes, origin, size):
	var covered_area = af.array_sum(sizes)
	var width = covered_area / size.y
	var leftover_x = origin.x + width
	var leftover_y = origin.y
	var leftover_dx = size.x - width
	var leftover_dy = size.y
	return Rect2(leftover_x, leftover_y, leftover_dx, leftover_dy)

func leftovercol(sizes, origin, size):
	var covered_area = af.array_sum(sizes)
	var height = covered_area / size.x
	var leftover_x = origin.x
	var leftover_y = origin.y + height
	var leftover_dx = size.x
	var leftover_dy = size.y - height
	return Rect2(leftover_x, leftover_y, leftover_dx, leftover_dy)


func leftover(sizes, origin, size):
	if size.x >= size.y:
		return leftoverrow(sizes, origin, size)
	return leftovercol(sizes, origin, size)


func normalize_sizes(sizes, size):
	var total_size = af.array_sum(sizes)
	var total_area = size.x * size.y
	for c in range(0, len(sizes)):
		sizes[c] = sizes[c] * total_area / total_size
	return sizes

func worst_ratio(sizes, origin, size):
	var maxes = []
	var layouts = layout(sizes, origin, size)
	for rect in layouts:
		maxes.append(max(rect.size.x / rect.size.y, rect.size.y / rect.size.x))
	return af.array_max(maxes)


func layoutrow(sizes, origin, size):
	var covered_area = af.array_sum(sizes)
	var width = covered_area / size.y
	var rects = []
	for size in sizes:
		rects.append(Rect2(origin.x, origin.y, width, size / width))
		origin.y += size / width
	return rects


func layoutcol(sizes, origin, size):
	var covered_area = af.array_sum(sizes)
	var height = covered_area / size.x
	var rects = []
	for size in sizes:
		rects.append(Rect2(origin.x, origin.y, size / height, height))
		origin.x += size / height
	return rects

func layout(sizes, origin, size):
	if size.x >= size.y:
		return layoutrow(sizes, origin, size)
	return layoutcol(sizes, origin, size)

func squarify(sizes, origin, size):
	if len(sizes) == 0:
		return []
	if len(sizes) == 1:
		return layout(sizes, origin, size)

	var i = 1
	while i < len(sizes) and worst_ratio(af.array_slice(sizes, 0, i), origin, size) \
		>= worst_ratio(af.array_slice(sizes, 0, i + 1), origin, size):
		i += 1
	var current = af.array_slice(sizes, 0, i)
	var remaining = af.array_slice(sizes, i, len(sizes))

	var leftovers = leftover(current, origin, size)
	return layout(current, origin, size) + squarify(remaining, leftovers.position, leftovers.size)
