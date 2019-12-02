extends Node2D
class_name ClutterGen

export var net_filename: String = "res://resources/bedroom_net.json"

const tile_size = Vector2(50, 50)
var placedObjects = []
var score = 0

var PetriNet = load("res://scripts/PetriNet.gd")
onready var SR = $"../TileMap"

var nets = []
var nets_by_names = {}

func _ready():
	# parse the net from the text file
	nets = parse_net()
	# get the initial tokens from the tilemap
	
	for t in SR.open_area_tiles:
		if not nets_by_names.has(t.first): 
			continue
		
		nets_by_names[t.first].put_token(PetriNet.Token.new("", "OPEN", t.second))
	
	for t in SR.by_wall_tiles:
		if not nets_by_names.has(t.first):
			continue
		
		nets_by_names[t.first].put_token(PetriNet.Token.new("", "WALL", t.second))
	
	for t in SR.corners:
		if not nets_by_names.has(t.first):
			continue
		
		nets_by_names[t.first].put_token(PetriNet.Token.new("", "CORNER", t.second))
		
	randomize()
	for net in nets:
		placedObjects += net.run()
	
	var tiles = {
		"OBJ_BED": "res://resources/bed.png",
		"OBJ_CLOSET": "res://resources/closet.png",
		"OBJ_BATHTUB": "res://resources/bathtub.png",
		"OBJ_TOILET": "res://resources/toilet.png",
		"OBJ_TABLE": "res://resources/table.png",
		"OBJ_FRIDGE": "res://resources/fridge.png",
	}
	
	for p in placedObjects:
		for t in p.placeTokens:
			"""
			SR.set_cellv(t.pos, tiles[p.name])
			"""
			var s = Sprite.new()
			s.texture = load(tiles[p.name])
			
			# rotate and move considering walls nearby
			s.position = SR.map_to_world(t.pos)
			
			if t.type == "WALL" or t.type == "CORNER":
				if SR.solid_tiles.has(t.pos + Vector2(0, -1)):
					# wall at the top
					print(p.name, " with wall at the top")
					s.position.y += (s.texture.get_size().y / 2)
					
				elif SR.solid_tiles.has(t.pos + Vector2(0, 1)):
					# wall at the bottom
					print(p.name, " with wall at the bot")
					s.rotate(deg2rad(180))
					s.position.y -= (s.texture.get_size().y / 2)
					
				if SR.solid_tiles.has(t.pos + Vector2(-1, 0)):
					# wall at the left
					print(p.name, " with wall at the lef")
					if t.type != "CORNER": s.rotate(deg2rad(270))
					s.position.x += (s.texture.get_size().x / 2)
					
				elif SR.solid_tiles.has(t.pos + Vector2(1, 0)):
					# wall at the right
					print(p.name, " with wall at the rig")
					if t.type != "CORNER": s.rotate(deg2rad(90))
					s.position.x -= (s.texture.get_size().x / 2)
					
			
			add_child(s)
	

func parse_net():
	var file = File.new()
	file.open(net_filename, file.READ)
	var text = file.get_as_text()
	var jNet = JSON.parse(text)
	file.close()
	
	if jNet.error != OK: # If parse has errors
		print("Error: ", jNet.error)
		print("Error Line: ", jNet.error_line)
		print("Error String: ", jNet.error_string)
		return null
	else:
		jNet = jNet.result
	
	"""
	JSON structure:
	{ pages: [...] }
	page:
		- name: string

		- tokens: [...]
			- type: string
			- pos: int array (not used for control nodes)

		- objects: [...]
			- name: string

		- places: [...]
			- name: string
				- 0th place must be named start, and 
			- tokens: [string] 
				- token names
				- (for control nodes with initial tokes, 
					start is filled by the room generator)


		- transitions: [...]
			- name: string
			- probability: float
			- pairs: [...]
				- from: string
				- to: string
				- sdp: float
				- sda: float
	"""
	
	var nets = []
	
	for page in jNet["pages"]:
		var name = page["name"]
		var net = PetriNet.new(name)
		
		for obj in page["objects"]:
			net.add_object(obj["name"])
		
		for token in page["tokens"]:
			if len(token["pos"]) == 2:
				net.add_token(token["name"], token["type"], Vector2(token["pos"][0], token["pos"][1]))
			else:
				net.add_token(token["name"], token["type"])
				
		for place in page["places"]:
			var p = net.add_place(place["name"])
			for tn in place["tokens"]:
				var t = net.find_token(tn)
				if not t:
					print("Error: unable to find token ", tn)
					return null
					
				p.put_token(t)
				
		for transition in page["transitions"]:
			var t = net.add_transition(transition["name"], transition["probability"])
			for edge in transition["pairs"]:
				var from = net.find_entity(edge["from"])
				var to = net.find_entity(edge["to"])
				# todo: error checking
				t.add_edge(from, to, edge["type"], edge["sdp"], edge["sda"])
		
		nets.append(net)
		nets_by_names[name] = net
		
	return nets