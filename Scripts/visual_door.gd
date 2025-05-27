class_name VisualDoor extends Door
@export var color : Color = Color.GRAY

static func create( ident : String, ch : String, dest : String, door_name : String, col : Color = Color.GRAY ) -> VisualDoor:
	var new_door = VisualDoor.new()
	new_door.id = ident
	new_door.choice = ch
	new_door.destination = dest
	new_door.name = door_name
	new_door.color = col
	#print( "*Created new door." )
	return new_door
	
func _enter_tree():
#{
	visible = false;
	
#}  // end _enter_tree()
