extends Node
class_name Edge

var source
var destination

# type of tokens that can move along an edge
var type

# standard deviation is placed on edge
# to allow specifying them for specific
# instances of objects
# i.e. fallen cup can roll further from the table 
# than one that stays on the table

# standard deviation of position
var sdp
# standard deviation of angle
var sda

func _init(source, destination, type = "ANY", sdp = 0, sda = 0):
	self.source = source
	self.destination = destination
	
	self.type = type
	
	self.sdp = sdp
	self.sda = sda

# TODO: add typechecking?
# But probably won't be called by anything other than Transition
func pull_token():
	return self.source.get_token(self.type)
	
func put_token(token):
	if self.type == "ANY" or token.type == self.type:
		self.destination.put_token(token)