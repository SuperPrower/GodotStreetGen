# extends "res://Scripts/Token.gd"
extends Node
class_name AnchorToken

"""
Although usually Petry Net's tokens used to
represent objects, Taylor at al. decided to 
use them to represent Anchor Points.
"""

var type
var pos: Vector2

func _init(type="ANY", pos=Vector2(0,0)):
	self.type = type
	self.pos = pos