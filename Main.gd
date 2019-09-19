extends Node2D

var PetriNet = preload("res://Scripts/PetriNet.gd")
var Token = preload("res://Scripts/AnchorToken.gd")
var Transition = preload("res://Scripts/Transition.gd")
var Edge = preload("res://Scripts/Edge.gd")
var Place = preload("res://Scripts/Place.gd")
var OutObject = preload("res://Scripts/OutputObject.gd")

"""
Rules:
	- Vending Machines get extra points if there one more nearby,
	- but lose points if there are too many
	
	- 
	
"""

const tile_size = Vector2(50, 50)
var placedObjects

func _ready():
	run_net()

func run_net():
	
	randomize()
	placedObjects = {}
	
	var tokens = [
		Token.new("ROAD_EDGE", Vector2(0, 0)),
		Token.new("ROAD_EDGE", Vector2(0, 1)),
		Token.new("ROAD_EDGE", Vector2(0, 2)),
		Token.new("ROAD_EDGE", Vector2(0, 3)),
		Token.new("ROAD_EDGE", Vector2(0, 4)),
		
		Token.new("STREET", Vector2(1, 0)),
		Token.new("STREET", Vector2(1, 1)),
		Token.new("STREET", Vector2(1, 2)),
		Token.new("STREET", Vector2(1, 3)),
		Token.new("STREET", Vector2(1, 4)),
		
		Token.new("STREET_EDGE", Vector2(2, 0)),
		Token.new("STREET_EDGE", Vector2(2, 1)),
		Token.new("STREET_EDGE", Vector2(2, 2)),
		Token.new("STREET_EDGE", Vector2(2, 3)),
		Token.new("STREET_EDGE", Vector2(2, 4)),
	]
	
	var places = {
		"START": Place.new()
	}
	
	places["START"].put_tokens(tokens)
	
	var transitions = [
		Transition.new(), # Make Street Lamp
		Transition.new() # Make Vending Machine
	]
	
	var objects = [
		OutObject.new("LAMP", 3),
		OutObject.new("VENDING_MACHINE", 2),
	]
	
	var edges = [
		Edge.new(places["START"], transitions[0], "ROAD_EDGE"),
		Edge.new(places["START"], transitions[1], "STREET_EDGE"),
		
		Edge.new(transitions[0], objects[0]),
		Edge.new(transitions[1], objects[1]),
	]
	
	transitions[0].add_edges(edges[0], edges[2])
	transitions[1].add_edges(edges[1], edges[3])
	
	var petriNet = PetriNet.new(transitions, objects)
	placedObjects = petriNet.run()
	
	# TODO: evaluate objects

func _draw():
	var color: Color
	
	color = Color.darkgray
	draw_rect(Rect2(Vector2(0,0), Vector2(150, 250)), color)
	
	# PetriNet produces dict of coordinate : object_name
	for k in placedObjects.keys():
		if placedObjects[k] == "LAMP":
			color = Color.black
		else:
			color = Color.orange
			
		draw_rect(Rect2(k * tile_size, tile_size), color)
	
func _process(delta):
	update()
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		run_net() 
	