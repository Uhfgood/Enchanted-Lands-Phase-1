class_name Door extends Resource

@export var choice : String = "0"
@export var destination : String = "blank_room"
@export var id : String = "drXXX"

static func create( ident : String, ch : String, dest : String ) -> Door:
	var new_door = Door.new()
	new_door.id = ident
	new_door.choice = ch
	new_door.destination = dest

	return new_door
