@tool
extends Node2D

# Custom signal to initialize rooms
#signal initialize_room()

# Flag to prevent load_all_rooms from running multiple times
var has_loaded_rooms: bool = false

func _ready():
	print( "***" )
	print( "EDITOR MAP READY" )
	if Engine.is_editor_hint():
		if not has_loaded_rooms:
			load_all_rooms()
			has_loaded_rooms = true
			#print( "***" )


func load_all_rooms():
	print("Running load_all_rooms")
	for child in get_children():
		remove_child(child)
		child.queue_free()

	# Step 1: Load all rooms into a dictionary
	var rooms_dict = {}  # Maps room name (e.g., "sn000-MainMenu") to Room node
	var file_list = []
	var file_name = ""

	# Load .tscn files
	var tscn_dir = DirAccess.open("res://Rooms/")
	if tscn_dir:
		file_list = tscn_dir.get_files()
		for item in file_list:
			file_name = item
			if file_name.ends_with(".tscn"):
				print("---")
				print( "Next tscn in file list: ", item)
				var scene_path = "res://Rooms/" + file_name
				var room = load(scene_path).instantiate()
				var room_name = room.name
				print( "room_name = ", room_name )
				rooms_dict[room_name] = room
				add_child(room)
				room.owner = get_tree().edited_scene_root
				room.editor_map = self
				
				for child in room.get_children():
					if child is Door:
						# Create a new Door instance with a unique name
						var editor_door = Door.new()
						editor_door.door_id = child.door_id
						editor_door.choice = child.choice
						editor_door.destination = child.destination
						editor_door.name = "em_" + child.name
						room.doors.append(editor_door)
						room.add_child(editor_door)
						editor_door.owner = get_tree().edited_scene_root
						
						
				room.SetupVisuals()  # Direct call

	# Load .json files
	file_list = []
	file_name = ""
	var json_dir = DirAccess.open("res://Rooms/")
	if json_dir:
		file_list = json_dir.get_files()
		for item in file_list:
			file_name = item
			if file_name.ends_with(".json"):
				print("---")
				print( "Next json in file list: ", item)
				var json_name = file_name.replace(".json", "")
				var room = Room.CreateFromJSON(json_name)
				if room:
					var room_name = room.name
					print( "JSON room name = ", room_name )
					rooms_dict[room_name] = room
					add_child(room)
					room.owner = get_tree().edited_scene_root
					for door in room.get_children():
						if door is Door:
							door.owner = get_tree().edited_scene_root
					room.editor_map = self
					room.SetupVisuals()  # Direct call
				if file_name.begins_with("lv005"):
					break

	print( "***" )
