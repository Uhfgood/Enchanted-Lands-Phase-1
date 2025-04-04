@tool
extends Node2D

# Custom signal to initialize rooms
#signal initialize_room()

# Flag to prevent load_all_rooms from running multiple times
var has_loaded_rooms: bool = false

# Moved these variables to the script level for clarity
var panel_width: float = 584  # From your debug output
var level_height: float = 300  # Vertical spacing between levels
var horizontal_spacing: float = 20  # Add a small gap between rooms (adjustable)
var root_room: String = "lv001sn01-MainMenu"
var rooms_dict: Dictionary = {}  # Maps room name to Room node
var room_tree: Dictionary = {}  # Maps room name to list of child room names
var room_positions: Dictionary = {}  # Maps room name to Vector2 position
var level_max_children: Dictionary = {}  # Maps level (int) to max number of children
var level_rooms: Dictionary = {}  # Maps level (int) to list of room names

func _ready():
	print("***")
	print("EDITOR MAP READY")
	if Engine.is_editor_hint():
		if not has_loaded_rooms:
			load_all_rooms()
			has_loaded_rooms = true
			print("***")

func calculate_level_max_children(room_name: String, level: int, visited: Dictionary):
	if room_name in visited:
		return
	visited[room_name] = true

	# Add the room to its level
	if not level in level_rooms:
		level_rooms[level] = []
	level_rooms[level].append(room_name)

	# Update the max children for this level
	var children = room_tree[room_name] if room_name in room_tree else []
	if not level in level_max_children:
		level_max_children[level] = 0
	level_max_children[level] = max(level_max_children[level], children.size())

	# Recursively process children
	for child_name in children:
		if child_name in rooms_dict:
			calculate_level_max_children(child_name, level + 1, visited)

func calculate_subtree_width(num_children: int) -> float:
	if num_children == 0:
		return panel_width
	return num_children * panel_width + (num_children - 1) * horizontal_spacing

func position_room(room_name: String, x_center: float, y_level: float, level: int, visited: Dictionary):
	if room_name in visited:
		return
	visited[room_name] = true

	# Position the current room
	var room = rooms_dict[room_name]
	room.position = Vector2(x_center - panel_width / 2, y_level)
	room_positions[room_name] = room.position

	# Position children
	var children = room_tree[room_name] if room_name in room_tree else []
	if children.size() == 0:
		return

	# Calculate the effective width for spacing the parents at this level
	var child_level = level + 1
	var max_children = level_max_children[child_level] if child_level in level_max_children else 1
	var max_subtree_width = calculate_subtree_width(max_children)

	# Calculate the actual subtree width for each child
	var child_subtree_widths = []
	for child_name in children:
		if child_name in rooms_dict:
			var child_children = room_tree[child_name] if child_name in room_tree else []
			var subtree_width = calculate_subtree_width(child_children.size())
			child_subtree_widths.append(subtree_width)

	# Use the maximum subtree width to position the parents
	var total_children_width = children.size() * max_subtree_width
	if children.size() > 1:
		total_children_width += horizontal_spacing * (children.size() - 1)

	# Calculate the starting x position for the children (centered under the parent)
	var start_x = x_center - total_children_width / 2
	var current_x = start_x

	# Position each child
	for i in range(children.size()):
		var child_name = children[i]
		if child_name in rooms_dict:
			var actual_subtree_width = child_subtree_widths[i]
			# Center the child's actual subtree within the allocated max_subtree_width space
			var child_x_center = current_x + max_subtree_width / 2
			position_room(child_name, child_x_center, y_level + level_height, level + 1, visited)
			# Adjust the child's position to center its actual subtree
			var child_x_adjusted = child_x_center - actual_subtree_width / 2
			rooms_dict[child_name].position.x = child_x_adjusted
			room_positions[child_name].x = child_x_adjusted
			current_x += max_subtree_width + horizontal_spacing  # Move to the next slot

func load_all_rooms():
	print("Running load_all_rooms")
	for child in get_children():
		remove_child(child)
		child.queue_free()

	# Step 1: Load all rooms into a dictionary
	rooms_dict.clear()  # Reset the dictionary
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
				print("Next tscn in file list: ", item)
				var scene_path = "res://Rooms/" + file_name
				var room = load(scene_path).instantiate()
				var room_name = room.name
				print("room_name = ", room_name)
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
				print("Next json in file list: ", item)
				var json_name = file_name.replace(".json", "")
				var room = Room.CreateFromJSON(json_name)
				if room:
					var room_name = room.name
					print("JSON room name = ", room_name)
					rooms_dict[room_name] = room
					add_child(room)
					room.owner = get_tree().edited_scene_root
					for door in room.get_children():
						if door is Door:
							door.owner = get_tree().edited_scene_root
					room.editor_map = self
					room.SetupVisuals()  # Direct call
				if file_name.begins_with("lv007"):
					break

	print("***")
	print("Building room tree.")
	# Step 2: Build the room tree
	room_tree.clear()  # Reset the dictionary
	print("Number of rooms in dictionary: ", rooms_dict.size())
	for room_name in rooms_dict:
		var room = rooms_dict[room_name]
		room_tree[room_name] = []
		for door in room.doors:
			var dest_name = door.destination
			var prefix_str = dest_name.substr(0, 10)
			var dest_substr = dest_name.substr(10, dest_name.length() - 21)
			var dest = prefix_str + room.ToPascalCase(dest_substr)
			print("dest = " + dest)
			if dest in rooms_dict:
				room_tree[room_name].append(dest)

	# Step 3: Calculate max children per level
	level_max_children.clear()
	level_rooms.clear()
	room_positions.clear()
	calculate_level_max_children(root_room, 0, {})

	# Step 4: Position rooms
	position_room(root_room, 0, 0, 0, {})

	print("Level max children: ", level_max_children)
	print("Level rooms: ", level_rooms)
	print("Room positions: ", room_positions)
