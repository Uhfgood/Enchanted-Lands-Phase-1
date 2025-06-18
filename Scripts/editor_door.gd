class_name EditorDoor extends Node2D
@export var color : Color = Color.GRAY

static func create( door_name : String, col : Color = Color.GRAY ) -> EditorDoor:
	var new_door = EditorDoor.new()
	new_door.name = door_name
	new_door.color = col
	return new_door
	
func _enter_tree():
#{
		visible = false;
		
#}  // end _enter_tree()
