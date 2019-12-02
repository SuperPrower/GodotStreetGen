extends TileMap

# Internal classes
class Pair:
	var first
	var second
	
	func _init(first = null, second = null):
		self.first = first
		self.second = second
	
class Room:
	var name = ""
	var room_rect = null
	var connected = []
	
	func _init(name, room_rect):
		self.name = name
		self.room_rect = room_rect

class FloorArea:
	var type = ""
	var rooms = []
	var area_rect = null
	
	func _init(type, rooms):
		self.type = type
		self.rooms = rooms

class PseudoDictionarySorter:
	static func sort(a, b):
		if a[1] < b[1]:
			return true
		return false
		
class PseudoDictionaryInverseSorter:
	static func sort(a, b):
		return !PseudoDictionarySorter.sort(a, b)

func pseudodict_values(pseudodict, index = 1):
	var out = []
	for item in pseudodict:
		out.append(item[index])
	return out

var TILE_WALL = tile_set.find_tile_by_name("wall")
var TILE_FLOOR = tile_set.find_tile_by_name("floor")
var TILE_DOOR = tile_set.find_tile_by_name("door")

# Special trick - replace some tiles by their representations to simplify clutter zone search
var TILE_CORNER = tile_set.find_tile_by_name("corner")
var TILE_BY_WALL = tile_set.find_tile_by_name("by_wall")
var TILE_OPEN = tile_set.find_tile_by_name("open")

# imports
const squarify = preload("res://scripts/squarify.gd")
onready var sq = squarify.new()
const array_func = preload("res://scripts/array_funcs.gd")
onready var af = array_func.new()

# exports
# Width and height (in tiles) of the building
export(int) var width = 100
export(int) var height = 100
# "Primary room" - a room from which a corridor will be built if needed
export(String) var main_room = "living"

# Publically-visible variables
# Tiles for clutter in tile space
var open_area_tiles = []
var by_wall_tiles = []
var corners = []

var solid_tiles = []

# NOTE: Can't use custom classes in export, hence the janky PseudoDict
# Also, custom dictionaries and classes are harder to sort and such, this is simpler
export(Array, Array) var service_room_sizes = [["kitchen", 2], ["pantry", 0], ["laundry", 1]]
export(Array, Array) var social_room_sizes = [["living", 5], ["dining", 0], ["toilet", 0]]
export(Array, Array) var private_room_sizes = [["bedroom", 4], ["master", 0], ["bathroom", 2], ["secondary", 0]]

func draw_box(rect):
	# Draws a black outline of the given rectangle
	var pos_x = rect.position.x
	var pos_y = rect.position.y
	var width = rect.size.x
	var height = rect.size.y
	for x in range(pos_x, pos_x + width):
		set_cell(x, pos_y, TILE_WALL)
		set_cell(x, pos_y + height - 1, TILE_WALL)
	for y in range(pos_y, pos_y + height):
		set_cell(pos_x, y, TILE_WALL)
		set_cell(pos_x + width - 1, y, TILE_WALL)

func label_room(rect, text):
	# Puts a label on the top-left part of the rectangle
	var label = Label.new()
	# hardcoded size, still kinda visible
	label.rect_scale = Vector2(7, 7)
	label.text = text
	label.rect_position = rect.position * cell_size
	# Shift by 2 tiles for visibility
	label.rect_position.x += cell_size.x * 2
	label.rect_position.y += cell_size.y * 2
	label.rect_size = rect.size
	# Make the text black
	label.add_color_override("font_color", Color(0, 0, 0))
	get_parent().call_deferred("add_child", label)

func fill_area(rect, cell):
	# Fills an area with a given cell index
	var pos_x = rect.position.x
	var pos_y = rect.position.y
	var width = rect.size.x
	var height = rect.size.y
	for x in range(pos_x, pos_x + width):
		for y in range(pos_y, pos_y + height):
			set_cell(x, y, cell)

func place_door(segment):
	# Tries to place a 6-tiles-wide door on a random point in a segment
	var start_point = Vector2(segment.position.x, segment.position.y)
	var end_point
	var vertical = false
	if segment.size.x == 1:
		# Vertical line
		end_point = Vector2(segment.position.x, segment.end.y)
		vertical = true
	else:
		# Horizontal line
		end_point = Vector2(segment.end.x, segment.position.y)
	
	# A door is 6 tiles wide. Don't want it any shorter
	if (end_point - start_point).length() < 6:
		return false
		
	# Provide some space
	if vertical:
		end_point.y -= 4
		start_point.y += 4
	else:
		end_point.x -= 4
		start_point.x += 4
		
	var random = RandomNumberGenerator.new()
	random.seed = randi()
	
	var door_origin = Vector2(random.randi_range(start_point.x, end_point.x), random.randi_range(start_point.y, end_point.y))

	if vertical:
		for y in range(door_origin.y - 3, door_origin.y + 3):
			set_cell(door_origin.x, y, TILE_DOOR)
	else:
		for x in range(door_origin.x - 3, door_origin.x + 3):
			set_cell(x, door_origin.y, TILE_DOOR)
			
	return true

func is_reachable(connectivity, start, end):
	# Simple method of checking for connectivity
	var possible = [start]
	var finished = []
	
	while len(possible) > 0:
		var checked = possible.pop_front()
		for room in connectivity[checked]:
			if not finished.has(room) and typeof(room) != TYPE_STRING:
				if room == end:
					return true
				possible.append(room)
		finished.append(checked)
	return false

func get_inner_points(rect):
	var segments = []
	if rect.position.x > 0 and rect.position.y > 0:
		# Top-left
		segments.append(rect.position)
	if rect.end.x < width and rect.position.y > 0:
		# Top-right
		segments.append(Vector2(rect.end.x, rect.position.y))
	if rect.position.x > 0 and rect.end.y < height:
		# Bottom-left
		segments.append(Vector2(rect.position.x, rect.end.y))
	if rect.end.x < width and rect.end.y < height:
		# Bottom-right
		segments.append(rect.end)
	return segments

func close(point1, point2):
	return (point1.x >= point2.x - 1 or point1.x <= point2.x + 1) and \
			(point1.y >= point2.y - 1 or point1.y <= point2.y + 1)

# Cell manipulation
func solid_cell(x, y):
	var cell = get_cell(x, y)
	return cell == TILE_DOOR or cell == TILE_WALL
	
func in_bounds(x, y):
	return x < width and x >= 0 and y < height and y >= 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up
	# Set the random seed
	randomize()
	
	# Adjust the camera
	var screen_size = self.get_viewport().size
	var zoom_ratio = max((width * cell_size.x) / screen_size.x, (height * cell_size.y) / screen_size.y)
	$camera.current = true
	$camera.offset = Vector2(position.x + (width * cell_size.x) / 2, position.y + (height * cell_size.y) / 2)
	# + 0.2 to zoom out a bit
	$camera.zoom = Vector2(1, 1) * (zoom_ratio + 0.2)

	# Generation step
	var build_area = Vector2(width, height)
	
	# Generate zones for different areas
	# Area of an area is considered to be equal to the sum of the rooms in it 
	var areas = [
	["service", af.array_sum(pseudodict_values(service_room_sizes)), service_room_sizes], 
	["social", af.array_sum(pseudodict_values(social_room_sizes)), social_room_sizes], 
	["private", af.array_sum(pseudodict_values(private_room_sizes)), private_room_sizes]]
	areas.sort_custom(PseudoDictionaryInverseSorter, "sort")
	var area_sizes = pseudodict_values(areas)
	area_sizes = sq.normalize_sizes(area_sizes, build_area)
	for c in range(0, len(area_sizes)):
		# Replace janky PseudoDictionaries
		areas[c] = FloorArea.new(areas[c][0], areas[c][2])
	var rects = sq.squarify(area_sizes, Vector2(0, 0), build_area)
	# Draw the room types
	for c in range(0, len(rects)):
		# Round up for easier calculations
		# Floor and ceil are used to effectively maximize the taken space
		areas[c].area_rect = Rect2(max(floor(rects[c].position.x), 0), max(floor(rects[c].position.y), 0), \
			min(ceil(rects[c].size.x), width), min(ceil(rects[c].size.y), height))
		fill_area(rects[c], TILE_FLOOR)
		# Debug zone colors
		#if areas[c].type == "service":
		#	fill_area(rects[c], 2)
		#elif areas[c].type == "private":
		#	fill_area(rects[c], 3)
		#else:
		#	fill_area(rects[c], 4)
	
	# We want the areas to share walls, but sometimes, we get perfect splits, which result in "thick" walls
	# Adjust such splits slightly to account for that
	for area in areas:
		for other_area in areas:
			if area != other_area:
				if area.area_rect.position.x == other_area.area_rect.end.x:
					area.area_rect.position.x -= 1
					area.area_rect.size.x += 1
				if area.area_rect.position.y == other_area.area_rect.end.y:
					area.area_rect.position.y -= 1
					area.area_rect.size.y += 1
		
	# NOTE: Not really needed, but can be used later
	# Draw the boundaries of the zones
	#for box in rects:
	#	draw_box(box)
		
	# Generate the rooms
	for area in areas:
		# Delete rooms with area of 0
		for c in range(len(area.rooms) - 1, -1, -1):
			if area.rooms[c][1] == 0:
				area.rooms.remove(c)
		# Sort the rooms
		area.rooms.sort_custom(PseudoDictionarySorter, "sort")
		# Get values for squarify
		var area_values = pseudodict_values(area.rooms)
		var sizes = sq.normalize_sizes(area_values, area.area_rect.size)
		var rooms = sq.squarify(sizes, area.area_rect.position, area.area_rect.size)
		for c in range(0, len(rooms)):
			# Replace janky pseudodicts with objects
			var new_room = Room.new(area.rooms[c][0], rooms[c])
			# Simplify the rooms to integer coordinates
			# Floor and ceil are used to effectively maximize the taken space
			new_room.room_rect = Rect2(max(floor(new_room.room_rect.position.x), 0), \
				max(floor(new_room.room_rect.position.y), 0), \
				min(ceil(new_room.room_rect.size.x), area.area_rect.size.x), \
				min(ceil(new_room.room_rect.size.y), area.area_rect.size.y))
			# Add the new room to the area
			area.rooms[c] = new_room
			
		# We want the rooms to share walls, but sometimes, we get perfect splits, which result in "thick" walls
		# Adjust such splits slightly to account for that
		# Sometimes, a thick wall is generated (due to rounding), but that looks to be rare and looks kinda interesting
		for room in area.rooms:
			for other_room in area.rooms:
				if room != other_room:
					if room.room_rect.position.x == other_room.room_rect.end.x:
						room.room_rect.position.x -= 1
						if room.room_rect.end.x < area.area_rect.end.x:
							room.room_rect.size.x += 1
					if room.room_rect.position.y == other_room.room_rect.end.y:
						room.room_rect.position.y -= 1
						if room.room_rect.end.y < area.area_rect.end.y:
							room.room_rect.size.y += 1
		
	# Collect all of the rooms
	var all_rooms = []
	# Dict: key = room name, value = array of adjacent rooms
	var room_adjacency = {}
	for area in areas:
		for room in area.rooms:
			all_rooms.append(room)
			
	# Intermediate output - walls of the rooms and the building
	# Later, windows and doors will be added
	for room in all_rooms:
		# Draw the room
		draw_box(room.room_rect)
		# Label it
		label_room(room.room_rect, room.name)
		
	# Build doors and windows
	# Go through all rooms and see which ones are adjacent
	for room in all_rooms:
		if not room_adjacency.has(room):
			room_adjacency[room] = []
		for test_room in all_rooms:
			if test_room != room:
				# Since we are using integer rectangles, the rectangles overlap naturally in the end
				# No need for any special checks
				if test_room.room_rect.intersects(room.room_rect):
					if not room_adjacency[room].has(test_room):
						if not room_adjacency.has(test_room):
							room_adjacency[test_room] = []
						room_adjacency[test_room].append(room)
						room_adjacency[room].append(test_room)
	
	# Get allowed adjacencies
	var file = File.new()
	file.open("res://resources/connectivity.json", file.READ)
	var text = file.get_as_text()
	var allowed_connections = JSON.parse(text).result
	file.close()
	
	# Modify the adjacency matrix to account for permitted connections
	for room in room_adjacency:
		for c in range(len(room_adjacency[room]) - 1, -1, -1):
			if not allowed_connections[room.name].has(room_adjacency[room][c].name):
				room_adjacency[room].remove(c)
		if allowed_connections[room.name].has("outside"):
			room_adjacency[room].append("outside")
			
	# Place doors in random points on clippings
	for room in room_adjacency:
		for adjacent in room_adjacency[room]:
			# Outside is represented just by a string, not by a room
			# Strings are special case - outside connectivity
			if typeof(adjacent) != TYPE_STRING:
				if not adjacent.connected.has(room):
					var segment = room.room_rect.clip(adjacent.room_rect)
					if place_door(segment):
						room.connected.append(adjacent)
						adjacent.connected.append(room)
			else:
				# Special case - outside connection
				# TODO: Add outside doors
				pass
				
	# TODO: Add windows
	
	# TODO: Add doors for loose stuff
	# Array instead of a dict for easier iteration
	var start_room = null
	
	# Find the "primary" room
	for room in all_rooms:
		if room.name == main_room:
			start_room = room
			
	# TODO: Check reachability from the "primary" room for every room, add doors if impassable
	
	# Generating tiles for clutter gen
	# Yellow - open space
	# Pink - corners
	# Cyan - near walls
	for x in range(0, width):
		for y in range(0, height):
			var cell = get_cell(x, y)
			if !solid_cell(x, y):
				var adjacent_wall = 0
				var adjacent_door = 0
				var adjacent_by_wall = 0
				
				# Check the 8 sides.
				for x_local in range (-1, 2):
					for y_local in range(-1, 2):
						if in_bounds(x + x_local, y + y_local):
							var adjacent = get_cell(x + x_local, y + y_local)
							if x_local % 3 == 0 or y_local % 3 == 0:
								# One of the cardinal directions
								if adjacent == TILE_WALL:
									adjacent_wall += 1
								elif adjacent == TILE_DOOR:
									adjacent_door += 1
							
							if adjacent == TILE_BY_WALL or adjacent == TILE_CORNER:
								adjacent_by_wall += 1
							
				var room_name = null
				var tile_point = Vector2(x, y)
				for room in all_rooms:
					if room.room_rect.has_point(tile_point):
						room_name = room.name
						break
						
				var tile = Pair.new(room_name, tile_point)
							
				if adjacent_wall + adjacent_door >= 2:
					corners.append(tile)
				elif adjacent_wall == 1 and adjacent_by_wall == 0:
					if randi() % 100 > 50:
						by_wall_tiles.append(tile)
						# Small trick here - we place the special tiles on the map itself to simplify future checks
						# REMEMBER TO REPLACE THE SPECIAL TILES LATER!
						set_cell(x, y, TILE_BY_WALL)
				else:
					if adjacent_door == 0 and adjacent_by_wall == 0:
						if x % 4 == 0 and y % 4 == 0:
							open_area_tiles.append(tile)
			else:
				solid_tiles.append(Vector2(x, y))
				
	# Cut down the amount of cells
	for c in range(len(open_area_tiles) - 1, -1, -1):
		if c % 2 == 0:
			open_area_tiles.remove(c)

	for c in range(len(by_wall_tiles) - 1, -1, -1):
		set_cellv(by_wall_tiles[c].second, TILE_FLOOR)
		if c % 2 == 0:
			by_wall_tiles.remove(c)
			
	# DEBUG: Clutter zone drawing
	#for cell in open_area_tiles:
	#	set_cellv(cell.second, TILE_OPEN)
	#for cell in by_wall_tiles:
	#	set_cellv(cell.second, TILE_BY_WALL)
	#for cell in corners:
	#	set_cellv(cell.second, TILE_CORNER)
	#for cell in solid_tiles:
	#	set_cellv(cell, TILE_DOOR)