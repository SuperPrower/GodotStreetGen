extends Node
class_name Place

"""
Place temporarily holds Tokens
"""

var tokens: Array

func _init():
	self.tokens = []
	
func put_token(token: AnchorToken):
	self.tokens.append(token)
	
func put_tokens(tokens: Array):
	self.tokens += tokens
	
func get_token(type="ANY"):
	
	self.tokens.shuffle()
	
	for i in range(len(self.tokens)):
		if type != "ANY" and self.tokens[i].type != type:
			continue
		
		var token = self.tokens[i]
		self.tokens.remove(i)
		
		return token
		
	return null