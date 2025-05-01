@tool
class_name Door extends Node2D

@export var choice: String = "0"
@export var destination: String = "blank_room"
@export var id: String = "drXXX"
var last_position: Vector2 = Vector2.ZERO

static func create(ident: String, ch: String, dest: String, door_name: String) -> Door:
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
		last_position = position # Store initial position

func _process(_delta):
	if Engine.is_editor_hint():
		if position != last_position:
			var delta = position - last_position
			var parent = get_parent()
			if parent is Room:
				print("Door ", name, " moved in editor by delta: ", delta, ", adjusting parent Room: ", parent.name)
				parent.position += delta
				last_position = position
			else:
				print("Warning: Door ", name, " moved but parent is not a Room: ", parent.name if parent else "null")
