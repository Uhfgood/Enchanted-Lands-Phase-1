class_name Door extends Node
@export var choice : String = "0"
@export var destination : String = "blank_room"

@export var door_id : String = "drXXX"

static func create( ident : String, ch : String, dest : String, door_name : String ) -> Door:
	var new_door = Door.new()
	new_door.door_id = ident
	new_door.choice = ch
	new_door.destination = dest
	new_door.name = door_name
	print( "Door name = ", new_door.name )
	return new_door
	
