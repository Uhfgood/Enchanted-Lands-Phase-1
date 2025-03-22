@tool
extends Node2D

func _ready():
	if Engine.is_editor_hint():
		load_all_rooms()

func load_all_rooms():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var file_list = []
	var file_name = ""
	var json_dir = DirAccess.open("res://Rooms/json_data/")
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
	file_name = ""
	var tscn_dir = DirAccess.open("res://Rooms/tscn_data/")
	if tscn_dir:
		file_list = tscn_dir.get_files()
		for item in file_list:
			file_name = item
			if file_name.ends_with(".tscn"):
				var scene_path = "res://Rooms/tscn_data/" + file_name
				var room = load(scene_path).instantiate()
				room.position = Vector2.ZERO
				add_child(room)
				room.owner = get_tree().edited_scene_root
			file_name = tscn_dir.get_next()
