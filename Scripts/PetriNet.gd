extends Node

var Token = preload("res://Scripts/AnchorToken.gd")
var Transition = preload("res://Scripts/Transition.gd")
var Edge = preload("res://Scripts/Edge.gd")

"""

AnchorPoint: Position and Orientation

Randomly choose transition to fire. When

"""

# var places
# var edges
var transitions
var objects

func _init(transitions, objects):
	# self.places = places
	# self.edges = edges
	self.transitions = transitions
	self.objects = objects
	
"""
Execution consists of making a list of live transitions 
and firing one randomly. If specified by the user, some 
transitions may have a chance of not firing even after 
being picked. This continues until there are no live 
transitions, either due to using up the available tokens 
or having the tokens end up in a place where they cannot be used.
"""
func run():
	while true:
		var live_transitions = []
		for i in range(len(self.transitions)):
			if self.transitions[i].live():
				live_transitions.append(self.transitions[i])
				
		if len(live_transitions) == 0:
			# done
			break
		
		live_transitions.shuffle()
		live_transitions[0].fire()
	
	var ret = {}
	for object in objects:
		for place in object.placeTokens:
			ret[place.pos] = object.objectName
			
	return ret