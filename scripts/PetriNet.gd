extends Node
class_name PetriNet

var objects
var tokens
var places
var transitions

var page_name

func _init(name):
	self.page_name = name
	self.objects = []
	self.tokens = []
	self.places = []
	self.transitions = []


func add_place(pname) -> Place:
	var p = Place.new(pname)
	self.places.append(p)
	
	return p

func find_place(pname) -> Place:
	for p in self.places:
		if p.name == pname:
			return p
	
	return null


func add_object(oname) -> OutputObject:
	var o = OutputObject.new(oname)
	self.objects.append(o)
	
	return o

func find_object(oname) -> OutputObject:
	for o in self.objects:
		if o.name == oname:
			return o
	
	return null


func add_transition(tname, probability = 1.0) -> Transition:
	var t = Transition.new(tname, probability)
	self.transitions.append(t)
	
	return t

func find_transition(tname) -> Transition:
	for t in self.transitions:
		if t.name == tname:
			return t
	
	return null

func add_token(tname: String, type: String = "ANY", pos: Vector2=Vector2(0,0)) -> Token:
	var t = Token.new(tname, type, pos)
	self.tokens.append(t)
	
	return t

func put_token(t: Token):
	var s = self.find_place("START")
	s.put_token(t)

func find_token(tname) -> Token:
	for t in self.tokens:
		if t.name == tname:
			return t
			
	return null


func find_entity(ename):
	for p in self.places:
		if p.name == ename:
			return p
			
	for o in self.objects:
		if o.name == ename:
			return o

	for t in self.transitions:
		if t.name == ename:
			return t

	for t in self.tokens:
		if t.name == ename:
			return t
	
	return null


func run():
	"""
	Execution consists of making a list of live transitions 
	and firing one randomly. If specified by the user, some 
	transitions may have a chance of not firing even after 
	being picked. This continues until there are no live 
	transitions, either due to using up the available tokens 
	or having the tokens end up in a place where they cannot be used.
	"""
	while true: 
		var live_transitions = []
		for t in self.transitions:
			if t.live():
				live_transitions.append(t)
				
		if len(live_transitions) == 0:
			break
		
		live_transitions.shuffle()
		live_transitions[0].fire()
		
	"""
	var ret = {}
	for object in objects:
		for place in object.placeTokens:
			ret[place.pos] = object.objectName
	"""
			
	return self.objects


## Inner Classes

class Token:
	"""
	Although usually Petry Net's tokens used to
	represent objects, Taylor at al. decided to 
	use them to represent Anchor Points.
	"""
	
	var name: String
	var type: String
	var pos: Vector2
	
	func _init(name:String, type: String = "ANY", pos=Vector2(0,0)):
		self.name = name
		self.type = type
		self.pos = pos


class Transition:
	var name: String
	var probability # how often this transition will fire if selected
	var edges: Array # holds pairs of edges to other edges
	
	func _init(name: String, probability = 1.0):
		self.name = name
		self.probability = probability
		self.edges = []
		
	func add_edge(incoming, outgoing = null, type = "ANY", sda = 0.0, sdp = 0.0):
		self.edges.append(Edge.new(incoming, outgoing, type, sda, sdp))
		
	func fire():
		for edge in edges:
			edge.fire()
		
	func live():
		"""
		A transition is called live if _each_ of the places 
		pointing to it contain at least one token.
		"""
		for edge in edges:
			if edge.live() == true:
				continue
			else:
				return false
				
		return true

	class Edge:
		var source
		var destination
		var type # type of tokens that can move along an edge
		var sdp # standard deviation of position
		var sda # standard deviation of angle
		
		func _init(source: Place, destination, type = "ANY", sdp = 0, sda = 0):
			self.source = source
			self.destination = destination
			
			self.type = type
			self.sdp = sdp
			self.sda = sda
		
		func live() -> bool:
			if len(source.tokens) == 0:
				return false
				
			var am_live = false
	
			for token in source.tokens:
				if self.type == "ANY" or token.type == self.type: 
					am_live = true
					break
					
			return am_live
			
		func fire():
			var t = source.get_token(self.type)
			# todo: error checking
			if destination != null:
				destination.put_token(t)


class Place:
	"""
	Place temporarily holds Tokens
	"""
	
	var tokens: Array
	var name: String
	
	func _init(name):
		self.name = name
		self.tokens = []
		
	func put_token(token: Token):
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


class OutputObject:
	"""
	Final destination of a Token.
	Represents an ingame entity (i.e. chair), 
	and Tokens represent where this entity will be placed
	"""
	
	var name
	var placeTokens: Array
	
	func _init(name):
		self.name = name
		self.placeTokens = []

	func put_token(placeToken):
		self.placeTokens.append(placeToken)