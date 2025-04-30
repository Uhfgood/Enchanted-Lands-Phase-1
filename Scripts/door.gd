class_name Door extends Node2D
@export var choice : String = "0"
@export var destination : String = "blank_room"

@export var id : String = "drXXX"

static func create( ident : String, ch : String, dest : String, door_name : String ) -> Door:
	var new_door = Door.new()
	new_door.id = ident
	new_door.choice = ch
	new_door.destination = dest
	new_door.name = door_name
	return new_door
	
func _enter_tree():
	if Engine.is_editor_hint():
		print("Door._enter_tree: Initializing door: ", name, " (ID: ", id, ", Destination: ", destination, ")")
		print("  Is inside tree: ", is_inside_tree())
		print("  Parent: ", get_parent().name if get_parent() else "null")
		print("  Owner: ", owner.name if owner else "null")
		print("  Stack: ", get_stack())

func _ready():
	if Engine.is_editor_hint():
		print("Door._ready: Initializing door: ", name, " (ID: ", id, ", Destination: ", destination, ")")
		print("  Is inside tree: ", is_inside_tree())
		print("  Parent: ", get_parent().name if get_parent() else "null")
		print("  Owner: ", owner.name if owner else "null")
		print("  Stack: ", get_stack())
