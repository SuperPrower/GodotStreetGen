extends Node
class_name OutputObject

"""
Final destination of a Token.
Represents an ingame entity (i.e. chair), 
and Tokens represent where this entity will be placed
"""

var objectName
var limit
var placeTokens: Array

func _init(objectName, limit=-1):
	self.objectName = objectName
	self.limit = limit
	self.placeTokens = []
	
# TODO: replace that with generic tokens going from control place to nowhere
func full():
	return limit >= 0 and len(placeTokens) == limit
	
func put_token(placeToken):
	if not full():
		self.placeTokens.append(placeToken)