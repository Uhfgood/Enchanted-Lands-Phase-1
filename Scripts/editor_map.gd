@tool
extends Node

var is_removing_room: bool = false

# Flag to prevent load_all_rooms from running multiple times
var has_loaded_rooms: bool = false
@onready var rooms = $Rooms
var currently_selected_room = null

const ROOMS_DIR = "res://Rooms/"
var rooms_dict = {}
var removed_rooms : Array[String] = []

# At the top of editor_map.gd, add:
var holding_node: Node = Node.new()

func _on_selection_changed():
#{
	# Ignore selection changes during removal
	if is_removing_room:
		print("Ignoring selection change during room removal.")
		return
	
	var editor_selection = EditorInterface.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()

	if not selected_nodes.is_empty():
	#{
		var selected_node = selected_nodes[0]
		# Safety check: Ensure the node is still valid
		if is_instance_valid(selected_node):
		#{
			print("Selected Node: ", selected_node.name)
			if(selected_node is VisualRoom):
				currently_selected_room = selected_node
			else:
				print( "Currently selected node is not a room." )
				currently_selected_room = null
			
		#} // end if is_instance_valid
		else:
			print("Selected node is invalid (possibly freed).")
			
	#}  // end if not selected_nodes.is_empty()
	else:
		print("No nodes selected")

#}  // end func _on_selection_changed()

func get_unique_room_label( base_label : String ) -> String:
#{
	# Start with the base label (e.g., "New Location")
	var label = base_label
	var suffix_num = 0
	var unique_label = label
	
	# Get all existing room labels under room_map
	var existing_labels = []
	for child in rooms.get_children():
		existing_labels.append( child.label )  # Use label property
	
	# Increment suffix until a unique label is found
	while unique_label in existing_labels:
	#{
		suffix_num += 1
		unique_label = base_label + " " + str( suffix_num )
	#}
	
	return unique_label

#}  // end func get_unique_room_label()

func _on_add_room_button_pressed():
#{
	print( "---" )
	var unique_label = get_unique_room_label( "New Location" )
	var new_id = "000_" + unique_label.replace( " ", "_" )
	var new_label = unique_label
	var new_desc = "There's nothing here yet.  Hit 0 to quit."
	var new_room = VisualRoom.Create( new_id, new_label, new_desc )
	AddRoomToEditorMap( new_room )

	# Select the new room in the scene tree
	var editor_selection = EditorInterface.get_selection()
	editor_selection.clear()
	editor_selection.add_node( new_room )
	print( "Selected new room: " + new_room.label + "." )
	print( "---" )

#}  // end _on_add_room_button_pressed():

# create a dictionary so I can rebuild inbound list later
func RebuildRoomsDictionary():	
	for room in rooms.get_children():
		rooms_dict[ room.id ] = room 

func AssignInboundRooms():
#{	
	## Pre-step: clear out all the inbound_rooms arrays
	for room in rooms_dict.values():
		room.ClearInboundRooms( rooms_dict )
#
	## Step 1:  Rebuild the inbound_rooms arrays for each room.
	for room in rooms_dict.values():
		room.RebuildInboundRooms( rooms_dict )
#
	## Step 2: Reorder inbound links to favor parent's x coordinate.
	for room in rooms_dict.values():
		room.ReorderInboundRooms( rooms_dict )
#
	## Step 3: Re-sort the doors
	for room in rooms_dict.values():
		room.ReSortDoors( rooms_dict )
	
#}  // end func AssignInboundRooms.

func _on_remove_room_button_pressed():
#{
	if not currently_selected_room:
		return
	
	# Set the removal flag
	is_removing_room = true
	
	# Disconnect the selection_changed signal to prevent it from firing during removal
	var editor_selection = EditorInterface.get_selection()
	if editor_selection.is_connected("selection_changed", Callable(self, "_on_selection_changed")):
		editor_selection.disconnect("selection_changed", Callable(self, "_on_selection_changed"))
	
	# Clear the editor's selection
	editor_selection.clear()
	
	# Get the room's ID to locate the files
	var room_id = currently_selected_room.id
	if room_id == "":
		print("Room " + currently_selected_room.label + " has no ID; removing from scene only.")
	else:
		removed_rooms.append(room_id)
	
	currently_selected_room.RemoveChildren()
	
	# Remove the room from the scene tree safely #
	if currently_selected_room.get_parent() == rooms:
	#{
		currently_selected_room.owner = null
		rooms.remove_child(currently_selected_room)
	#}
	else:
		print("Warning: Room is not a child of Rooms node: " + room_id)
	
	# Free the room node
	holding_node.add_child(currently_selected_room)

	# Clear the selected room
	currently_selected_room = null
	
	# Reset the removal flag
	is_removing_room = false
	
	AssignInboundRooms()

	# Update inbound links and visuals for remaining rooms
	for room in rooms.get_children():
		room.UpdateInboundVisuals()
		room.UpdateDoorLines()
	
#} // end func _on_remove_room_button_pressed
	
func _on_save_button_pressed():
#{
	RebuildRoomsDictionary()

	# wanted to create all the doors before assinging inbounds
	for room in rooms.get_children():
		room.CreateDoorsFromSpecs()

	# assign inbounds before saving any rooms
	AssignInboundRooms()

	for room in rooms_dict.values():
		room.UpdateDoorVisuals()
		room.UpdateInboundVisuals()
		room.UpdateDoorLines()

	for room in rooms.get_children():
	#{
		var filename = room.id + ".meta"
		if FileAccess.file_exists( ROOMS_DIR + filename ):
		#{
			SaveMetadataForRoom( room, filename )
		#}
		else:
		#{
			CreateNewMetaFile( filename )
			SaveMetadataForRoom( room, filename )
		#}
			
		filename = room.id + ".json"
		SaveRoomDataForRoom( room, filename )	
		
		if( room.id != room.original_id ):
		#{
			var old_json_path = ROOMS_DIR + room.original_id + ".json"
			if( FileAccess.file_exists( old_json_path ) ):
				DirAccess.open( ROOMS_DIR ).remove( old_json_path )
			var old_meta_path = ROOMS_DIR + room.original_id + ".meta"
			if( FileAccess.file_exists( old_meta_path ) ):
				DirAccess.open( ROOMS_DIR ).remove( old_meta_path )
			room.original_id = room.id	
			
		#}  // end if( room.id...

	#} // end for

	# Reselect the node after saving
	if currently_selected_room:
	#{
		var editor_selection = EditorInterface.get_selection()
		editor_selection.clear()
		editor_selection.add_node( currently_selected_room )
	#}
	
	for room_id in removed_rooms:
	#{
		# Delete the JSON file
		var json_path = "res://Rooms/" + room_id + ".json"
		var dir = DirAccess.open( "res://Rooms" )
		if dir and dir.file_exists( json_path ):
		#{
			var error = dir.remove( json_path )
			if error == OK:
				print( "Deleted JSON file: " + json_path + "." )
			else:
				print( "Failed to delete JSON file: " + json_path + "." )
		#}
		else:
			print( "No JSON file found for " + room_id + "." )
		
		# Delete the meta file, if it exists meta
		var meta_path = "res://Rooms/" + room_id + ".meta"
		if dir and dir.file_exists( meta_path ):
		#{
			var error = dir.remove( meta_path )
			if error == OK:
				print( "Deleted meta file: " + meta_path + "." )
			else:
				print( "Failed to delete meta file: " + meta_path + "." )
		#}
		else:
			print( "No meta file found for " + room_id + "." )
	
	#}  // end for room_id
	
	removed_rooms.clear()
	
#} // end func _on_save_button_pressed()
	
func _ready():
	holding_node.name = "HoldingNode"
	get_tree().root.add_child.call_deferred(holding_node)
	holding_node.set_owner(null)
	if not has_loaded_rooms:
		LoadAllRooms()
		has_loaded_rooms = true
		rooms.set_meta("_edit_lock_", true)


func AddRoomToEditorMap( room : VisualRoom ):
#{
	if not room:
		print( "  Error: Room is null" )
		return
	rooms.add_child( room) 
	room.SetOwner( self )
	
	# Rebuild the doors array from children
	room.RebuildDoors()
	room.editor_map = self
	room.SetupVisuals()
	
#}  // end func AddRoomToEditorMap
	
func CreateNewMetaFile( filename ):
#{
	var metaname = filename
	if( filename.ends_with( ".json" ) ): 
		metaname = filename.replace(".json", ".meta")
	if not FileAccess.file_exists( ROOMS_DIR + metaname ):
		var meta_file = FileAccess.open( ROOMS_DIR + metaname, FileAccess.WRITE )
		if FileAccess.get_open_error() == OK:
			var meta_data = {"x": 0, "y": 0}
			meta_file.store_string( JSON.stringify( meta_data ) )
			meta_file.close()
		
#} // end func LoadMetadataForRoom()

func SaveMetadataForRoom( room, filename ):
#{
	var metapath = ROOMS_DIR + filename
	if FileAccess.file_exists( metapath ):
		var file = FileAccess.open( metapath, FileAccess.WRITE )
		if FileAccess.get_open_error() == OK:
			var meta_data = {"x": room.position.x, "y": room.position.y}
			file.store_string( JSON.stringify( meta_data ) )
			file.close()
		else:
			print( "Couldn't open file for writing." )
	else:
		CreateNewMetaFile( filename )
		
#} // end func SaveMetadataForRoom()

func SaveRoomDataForRoom(room, filename: String):
#{
	var jsonpath = ROOMS_DIR + filename
	var file = FileAccess.open(jsonpath, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		# Manually construct the JSON string with the desired order
		var json_str = "{\n"
		json_str += '    "id": ' + JSON.stringify(room.id) + ",\n"
		json_str += '    "label": ' + JSON.stringify(room.label) + ",\n"
		json_str += '    "description": ' + JSON.stringify(room.description) + ",\n"
		
		# inbound data
		json_str += '    "inbound":\n'
		json_str += '    [\n'

		var in_strings = []
		var in_count = 0
		for inbound in room.inbound_rooms:
			if( inbound != "" ):
				var in_data = ''
				in_data += '        ' + JSON.stringify( inbound )
				in_strings.append( in_data )
				in_count += 1
		
		for i in range( in_count ):
			json_str += in_strings[ i ]
			if( i < in_strings.size() - 1 ):
				json_str += ",\n"		
			
		if in_strings.size() > 0:
			json_str += "\n"
		json_str += "    ],\n"
		
		# door data
		json_str += '    "doors":\n'
		json_str += '    [\n'

		var door_strings = []
		for door in room.doors:
			var door_data = '        {\n'  # Fixed: Removed erroneous "\ LandingPage"
			door_data += '            "id": ' + JSON.stringify(door.id) + ',\n'
			door_data += '            "choice": ' + JSON.stringify(door.choice) + ',\n'
			door_data += '            "destination": ' + JSON.stringify(door.destination) + '\n'
			door_data += '        }'
			door_strings.append(door_data)
		
		for i in range(door_strings.size()):
			json_str += door_strings[i]
			if i < door_strings.size() - 1:
				json_str += ",\n"		
			
		if door_strings.size() > 0:
			json_str += "\n"
		json_str += "    ]\n"

		json_str += "}"
		file.store_string(json_str)
		file.close()
		
		room.UpdateDoorVisuals()
		room.UpdateInboundVisuals()
		room.UpdateDoorLines()
		
		print("Room data saved for: ", filename)
	else:
		print("Couldn't open file for writing: ", jsonpath)
		
#} // end func SaveRoomDataForRoom()

func LoadMetadataForRoom( room, filename ):
#{
	var metapath = filename.replace(".json", ".meta")
	metapath = "res://Rooms/" + metapath
	if FileAccess.file_exists( metapath ):
		var file = FileAccess.open( metapath, FileAccess.READ )
		var meta_data = JSON.parse_string( file.get_as_text() )
		file.close()
		if meta_data:
			room.position.x = meta_data[ "x" ]
			room.position.y = meta_data[ "y" ]
		else:
			print( "No meta data read." )
		
#} // end func LoadMetadataForRoom()

func _visit_room(room: Node, sorted_rooms: Array, visited: Dictionary, temp_visited: Dictionary) -> void:
	if room.id in temp_visited:
		print("Warning: Cycle detected involving room ", room.id)
		return
	if room.id in visited:
		return
	temp_visited[room.id] = true

	# Visit all rooms that depend on this room (via inbound_rooms)
	for inbound_id in room.inbound_rooms:
		if inbound_id != "" and rooms_dict.has(inbound_id):
			var source_room = rooms_dict[inbound_id]
			_visit_room(source_room, sorted_rooms, visited, temp_visited)
	temp_visited.erase(room.id)
	visited[room.id] = true
	sorted_rooms.push_front(room)
	
func topological_sort_rooms() -> Array:
	var sorted_rooms = []
	var visited = {}
	var temp_visited = {}

	for room in rooms.get_children():
		if not (room.id in visited):
			_visit_room(room, sorted_rooms, visited, temp_visited)
	return sorted_rooms
	
func LoadAllRooms():
	print("Running load_all_rooms")
	
	rooms_dict.clear()
	
	for child in rooms.get_children():
		rooms.remove_child(child)
		child.queue_free()

	# Step 1: Load all rooms into a dictionary
	var filelist = []
	var filename = ""
	var json_dir = DirAccess.open("res://Rooms/")
	if json_dir:
		filelist = json_dir.get_files()
		for item in filelist:
			filename = item
			if filename.ends_with(".json"):
				var json_name = filename.replace(".json", "")
				var room = VisualRoom.CreateFromJSON(json_name)
				if room:
					rooms_dict[ room.id ] = room
					AddRoomToEditorMap(room)
					LoadMetadataForRoom(room, filename)
				if filename.begins_with("004"):
					break

	# Step 2: Assign inbound rooms for all rooms
	AssignInboundRooms()

	# Step 3: Update visuals for all rooms in dependency order
	var sorted_rooms = topological_sort_rooms()
	for room in sorted_rooms:
		room.UpdateDoorVisuals()
		room.UpdateInboundVisuals()
		room.UpdateDoorLines()

	# Step 4: Initialize previous positions
	previous_positions.clear()
	for room in rooms.get_children():
		if room is VisualRoom:
			previous_positions[room.id] = room.position
	
	RebuildRoomsDictionary()
	for room in rooms_dict.values():
		room.UpdateDoorVisuals()
		room.UpdateInboundVisuals()
		room.UpdateDoorLines()

func _exit_tree():
	if rooms:
		for room in rooms.get_children():
			if room is VisualRoom:
				room.RemoveChildren()
				rooms.remove_child(room)
				room.queue_free()
			else:
				rooms.remove_child(room)
				room.queue_free()
	else:
		print("  Rooms node not found")
		
	# Existing cleanup for holding_node
	if holding_node:
		for child in holding_node.get_children():
			child.queue_free()
		holding_node.queue_free()
		holding_node = null
	
	# Dictionary to store previous positions of rooms
var previous_positions: Dictionary = {}

func update_lines_for_room_and_dependents(room: Node) -> void:
	# Update lines for this room (outbound lines)
	room.UpdateDoorLines()
	
	# Update lines for all rooms that have this room as a destination (inbound lines)
	for other_room in rooms.get_children():
		if other_room != room and other_room is VisualRoom:
			for door in other_room.doors:
				if door.destination == room.id:
					other_room.UpdateDoorLines()
					break
					
func _process(_delta: float) -> void:
	#if Engine.is_editor_hint():
	for room in rooms.get_children():
		if room is VisualRoom:
			var current_pos = room.position
			var room_id = room.id
			if previous_positions.has(room_id):
				if previous_positions[room_id] != current_pos:
					update_lines_for_room_and_dependents(room)
			previous_positions[room_id] = current_pos
