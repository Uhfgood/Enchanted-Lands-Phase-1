@tool
extends Node2D

# Flag to prevent load_all_rooms from running multiple times
var has_loaded_rooms: bool = false

func _ready():
	if Engine.is_editor_hint():
		if not has_loaded_rooms:
			load_all_rooms()
			has_loaded_rooms = true

func load_all_rooms():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var file_list = []
	var file_name = ""
	
	var tscn_dir = DirAccess.open("res://Rooms/")
	if tscn_dir:
		file_list = tscn_dir.get_files()
		for item in file_list:
			file_name = item
			if file_name.ends_with(".tscn"):
				var scene_path = "res://Rooms/" + file_name
				var room = load(scene_path).instantiate()
				room.position = Vector2.ZERO
				add_child(room)
				room.owner = get_tree().edited_scene_root
			file_name = tscn_dir.get_next()
		
	file_list = []
	file_name = ""
	
	var json_dir = DirAccess.open("res://Rooms/")
	if json_dir:
		file_list = json_dir.get_files()
		for item in file_list:
			file_name = item
			if file_name.ends_with(".json"):
				var json_name = file_name.replace(".json", "")
				var room = Room.CreateFromJSON(json_name)
				if room:
					room.position = Vector2.ZERO
					add_child(room)
					room.owner = get_tree().edited_scene_root
					#Set owner for all Door children
					for door in room.get_children():
						if door is Door:
							door.owner = get_tree().edited_scene_root
				if file_name.begins_with("rm004"):
					break;
