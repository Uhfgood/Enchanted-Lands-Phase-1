@tool
extends Node2D

# Custom signal to initialize rooms
#signal initialize_room()

# Flag to prevent load_all_rooms from running multiple times
var has_loaded_rooms: bool = false

# Positioning variables
var panel_width: int = 584  # From your debug output
var horizontal_gap: int = 50  # Gap between rooms
var level_height: int = 300  # Vertical spacing between levels
var y_offset: int = 0  # Starting Y position
var max_children_per_level: Array = []  # Array: max_children_per_level[i] is the max number of children for any parent in level i

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

	# Step 4: Find the widest group in each level
	max_children_per_level.clear()  # Clear the array in case this function is called multiple times
	for level_idx in range(levels.size()):
		var max_children = 0  # Start at 0 since some levels may have no children
		# For each room in the previous level, count its children (which are in the current level)
		if level_idx == 0:
			# For the root level, use the number of children of the root
			max_children = room_tree[root_room].size()
		else:
			var parent_level = levels[level_idx - 1]
			for parent_name in parent_level:
				var child_count = room_tree[parent_name].size()
				max_children = max(max_children, child_count)
		max_children_per_level.append(max_children)
	print("Max children per level: ", max_children_per_level)

	# Step 5: Position rooms recursively
	# Start positioning from the root
	var root = rooms_dict[root_room]
	root.position = Vector2(0, y_offset)  # Start at the top center
	position_room(root_room, 0, rooms_dict, room_tree)

# Helper function to position a room and its children recursively
func position_room(room_name: String, level_idx: int, rooms_dict: Dictionary, room_tree: Dictionary) -> Dictionary:
	var room = rooms_dict[room_name]
	var level_y = y_offset + level_idx * level_height
	var children = room_tree[room_name]
	
	# Base case: If no children, return the room's bounds
	if children.size() == 0:
		return {"x_min": room.position.x - panel_width / 2.0, "x_max": room.position.x + panel_width / 2.0, "center_x": room.position.x}
	
	# Recursive case: Position all children first
	var child_positions = []
	var child_level = level_idx + 1
	var group_width = max_children_per_level[child_level] * (panel_width + horizontal_gap) - horizontal_gap if max_children_per_level[child_level] > 0 else panel_width
	
	# Temporarily position each child to calculate its subtree
	for child_name in children:
		var child = rooms_dict[child_name]
		child.position = Vector2(0, y_offset + child_level * level_height)
		var child_result = position_room(child_name, child_level, rooms_dict, room_tree)
		child_positions.append(child_result)
	
	# Position the children within the "big box" centered under the parent
	if children.size() > 0:
		# Calculate the starting x position to center the group under the parent
		var start_x = room.position.x - (group_width / 2.0)
		var child_spacing = (group_width - (children.size() * panel_width)) / max(1, children.size() - 1) if children.size() > 1 else 0
		var current_x = start_x
		
		for i in range(children.size()):
			var child = rooms_dict[children[i]]
			var child_result = child_positions[i]
			
			# Position the child within the "big box"
			var new_center_x = current_x + panel_width / 2.0
			var offset = new_center_x - child_result["center_x"]
			child.position.x = new_center_x
			child_positions[i]["x_min"] = child_result["x_min"] + offset
			child_positions[i]["x_max"] = child_result["x_max"] + offset
			child_positions[i]["center_x"] = new_center_x
			
			# Move current_x to the next position
			if children.size() > 1:
				current_x += panel_width + child_spacing
			else:
				current_x += panel_width
	
	# Calculate the group's bounds
	var x_min = child_positions[0]["x_min"] if children.size() > 0 else room.position.x - panel_width / 2.0
	var x_max = child_positions[children.size() - 1]["x_max"] if children.size() > 0 else room.position.x + panel_width / 2.0
	var center_x = (x_min + x_max) / 2.0
	
	# Reposition the parent to be centered over its children
	room.position.x = center_x
	
	return {"x_min": x_min, "x_max": x_max, "center_x": center_x}
