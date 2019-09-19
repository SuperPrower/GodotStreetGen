extends Node
class_name Transition

var Edge = preload("res://Scripts/Edge.gd")

"""
For each incoming edge, the user must specify which 
outgoing edge will get the token or that the token is 
to be discarded.
"""

# how often this transition will fire if selected
var probability

# holds pairs of edges to other edges
var edgePairs

func _init(probability = 1):
	self.edgePairs = []
	self.probability = probability
	
func add_edges(incoming: Edge, outgoing = null):
	self.edgePairs.append([incoming, outgoing])
	
func fire():
	for pair in edgePairs:
		var token = pair[0].pull_token()
		if pair[1] != null:
			pair[1].put_token(token)
	
"""
A transition is called live if _each_ of the places 
pointing to it contain at least one token.

TODO: _any_ token, or one that could pass?
"""	
func live():
	for pair in edgePairs:
		var edge = pair[0]
		if len(edge.source.tokens) == 0:
			return false
			
		var edge_live = false

		for token in edge.source.tokens:
			if token.type == edge.type: 
				edge_live = true
				break
				
		if not edge_live:
			return false  # there isn't a token that matches this edge
			
		# TODO: check if there is a token that can pass outgoing edge
			
	return true
	