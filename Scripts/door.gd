class_name Door # extends Node2D
@export var choice : String = "0"
@export var destination : String = "blank_room"
@export var id : String = "drXXX"

#static func create( ident : String, ch : String, dest : String, door_name : String ) -> Door:
static func create( ident : String, ch : String, dest : String ) -> Door:
	var new_door = Door.new()
	new_door.id = ident
	new_door.choice = ch
	new_door.destination = dest
	#new_door.name = door_name
	#print( "*Created new door." )
	return new_door
