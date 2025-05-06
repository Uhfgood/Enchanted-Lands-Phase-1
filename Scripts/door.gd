class_name Door extends Node2D
@export var choice : String = "0"
@export var destination : String = "blank_room"
@export var id : String = "drXXX"
@export var color : Color = Color.GRAY

static func create( ident : String, ch : String, dest : String, door_name : String, col : Color = Color.GRAY ) -> Door:
	var new_door = Door.new()
	new_door.id = ident
	new_door.choice = ch
	new_door.destination = dest
	new_door.name = door_name
	new_door.color = col
	print( "*Created new door." )
	return new_door
	
func _enter_tree():
#{
	if Engine.is_editor_hint():
	#{
		print("Door._enter_tree: Initializing door: ", name, " (ID: ", id, ", Destination: ", destination, ")")
		print("  Is inside tree: ", is_inside_tree())
		var parent = get_parent()
		print("  Parent: ", parent.name if parent else "null")
		var owner_value = owner
		print("  Owner: ", owner_value.name if owner_value else "null")
		print("  Stack: ", get_stack())

		visible = false;
		
	#} // end if
	
#}  // end _enter_tree()

func _ready():
#{
	if Engine.is_editor_hint():
	#{
		print("Door._ready: Initializing door: ", name, " (ID: ", id, ", Destination: ", destination, ")")
		print("  Is inside tree: ", is_inside_tree())
		var parent = get_parent()
		print("  Parent: ", parent.name if parent else "null")
		var owner_value = owner
		print("  Owner: ", owner_value.name if owner_value else "null")
		print("  Stack: ", get_stack())

	#}  // end if
	
#}  // end _ready()
