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
			print( "***" )


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
	print( "Building room tree." )
	# Step 2: Build the room tree
	var room_tree = {}  # Maps room name to list of child room names
	print( "Number of rooms in dictionary: ", rooms_dict.size())
	for room_name in rooms_dict:
		var room = rooms_dict[room_name]
		room_tree[room_name] = []
		for door in room.doors:
			#var destination = door.destination
			#var dest = door.destination.substr( 0, 10 ) + room.ToPascalCase( ) # door.destination.substr( 6 ) )
			var dest_name = door.destination
			var prefix_str = dest_name.substr( 0, 10 )
			var dest_substr = dest_name.substr( 10, dest_name.length() - 21 )
			var dest = prefix_str + room.ToPascalCase( dest_substr )
			print( "dest = " + dest )
			if dest in rooms_dict:
				room_tree[room_name].append(dest)

	# Step 3: Organize rooms by level
	var levels = []  # Array of arrays: levels[i] is a list of room names at level i
	var root_room = "lv001sn01-MainMenu"  # Starting point
	var to_process = [[root_room]]  # Queue of rooms to process by level
	var processed = {root_room: true}  # Track which rooms have been processed

	while to_process.size() > 0:
		var current_level = to_process.pop_front()
		levels.append(current_level)
		var next_level = []
		for room_name in current_level:
			for child_name in room_tree[room_name]:
				if not child_name in processed:
					next_level.append(child_name)
					processed[child_name] = true
		if next_level.size() > 0:
			to_process.append(next_level)

	print("Levels: ", levels)

	# Step 4: Position rooms
	var panel_width = 584  # From your debug output
	var level_height = 300  # Vertical spacing between levels
	var base_x = 0  # Center X position for the root
	var y_offset = 0  # Starting Y position

	for level_idx in range(levels.size()):
		var level = levels[level_idx]
		var level_y = y_offset + level_idx * level_height
		var total_width = (level.size() - 1) * panel_width  # Total width needed for this level
		var start_x = base_x - total_width / 2  # Center the level

		var current_x = start_x
		for room_name in level:
			var room = rooms_dict[room_name]
			room.position = Vector2(current_x, level_y)
			current_x += panel_width  # Simple spacing for now
