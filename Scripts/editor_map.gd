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
			if(selected_node is Room):
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
	var new_room = Room.Create( new_id, new_label, new_desc )
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
	
	#print( "[[[ BuildRoomsDictionary ]]]")
	for room in rooms.get_children():
		rooms_dict[ room.id ] = room 
		#print( "  " + rooms_dict[ room.id ].id )
	
	#print( "[[[ Size of rooms_dict: " + str( rooms_dict.size() ) + " ]]]" )
	
func AssignInboundRooms():
#{	
	# Pre-step: clear out all the inbound_rooms arrays
	for room in rooms_dict.values():
		var inbound_array = room.inbound_rooms
		for i in range( inbound_array.size() ):
			inbound_array[ i ] = ""

	# Step 1:  Rebuild the inbound_rooms arrays for each room.
	for room in rooms_dict.values():
	#{
		for door in room.doors:
		#{
			if( rooms_dict.has( door.destination ) ):
			#{
				var dest_room = rooms_dict[ door.destination ]
				
				for i in range( dest_room.inbound_rooms.size() ):
					if( dest_room.inbound_rooms[ i ] == "" ):
						dest_room.inbound_rooms[ i ] = room.id;
						break;
						
			#}  // end if rooms_dict.has...
			else:
				# Just warning when there's a door but the destination is missing.
				print( "Room: " + room.id + ", Door dest. " + door.destination + " does not exist in rooms_dict." )
			
		#} // end for door

	#}  // end for room

	# Step 2: Reorder inbound links to favor parent's x coordinate.
	var inbound_data = []
	for room in rooms_dict.values():
	#{
		inbound_data.clear()
		
		# let's populate the inbound_data array
		for inbound in room.inbound_rooms:
		#{
			if( inbound != "" and rooms_dict.has( inbound ) ):
				var inbound_room = rooms_dict[ inbound ]
				var pair = [ inbound_room.id, inbound_room.position.x ]
				inbound_data.append( pair )
				
		#}  // end for i
		
		inbound_data.sort_custom( func( a, b ): return a[ 1 ] < b[ 1 ] )

		# repopulate rooms
		for i in range( inbound_data.size() ):
			room.inbound_rooms[ i ] = inbound_data[ i ][ 0 ]
			
		#print( "Room: " + room.id + ", inbound: " + str( inbound_data ) )
		
	#}  // end for room

	# Step 3: Re-sort the doors
	var door_data = []
	for room in rooms_dict.values():
	#{
		door_data.clear()
		for door in room.doors:
		#{
			if( rooms_dict.has( door.destination ) ):
				var dest_x = rooms_dict[ door.destination ].position.x
				var pair = [ door, dest_x ]
				door_data.append( pair )
			else:
				door_data.append( [ door, INF ] )
				
		#} // end for door
		
		door_data.sort_custom( func( a, b ): return a[ 1 ] < b[ 1 ] )
		
		# repopulate the doors array
		room.doors.clear()
		for i in range( door_data.size() ):
			room.doors.append( door_data[ i ][ 0 ] )
	
		room.UpdateDoorVisuals()
		room.UpdateDoorLines()
		
		#print("Room: " + room.id + ", doors: " + str(door_data))
		
	#}  // for room
	
	
#}  // end func AssignInboundRooms.

func _on_remove_room_button_pressed():
#{
	#print("Removing child from scene tree.")
	if not currently_selected_room:
		#print("No room selected to remove.")
		return
	
	# Set the removal flag
	is_removing_room = true
	
	# Disconnect the selection_changed signal to prevent it from firing during removal
	var editor_selection = EditorInterface.get_selection()
	if editor_selection.is_connected("selection_changed", Callable(self, "_on_selection_changed")):
		editor_selection.disconnect("selection_changed", Callable(self, "_on_selection_changed"))
		#print("Disconnected selection_changed signal during removal.")
	
	# Clear the editor's selection
	editor_selection.clear()
	#print("Editor selection cleared.")
	
	# Get the room's ID to locate the files
	var room_id = currently_selected_room.id
	if room_id == "":
		print("Room " + currently_selected_room.label + " has no ID; removing from scene only.")
	else:
		#print("Attempting to append " + room_id + " to 'removed_rooms'")
		removed_rooms.append(room_id)
	
	# Debug: Log all children before removal
	#print("Children before removal: ", currently_selected_room.get_child_count())
	#for child in currently_selected_room.get_children():
	#	print("Child found: ", child.name, " (Type: ", child.get_class(), ")")
	
	# Explicitly clear the doors array to ensure consistency
	if currently_selected_room.doors:
		#print("Clearing doors array: ", currently_selected_room.doors.size(), " doors")
		currently_selected_room.doors.clear()
	
	# Remove and free all child nodes
	for child in currently_selected_room.get_children():
		#print("Removing child: ", child.name)
		currently_selected_room.remove_child(child)
		child.queue_free()
	
	# Debug: Confirm no children remain
	#print("Children remaining after removal: ", currently_selected_room.get_child_count())
	
	# Remove the room from the scene tree safely #
	if currently_selected_room.get_parent() == rooms:
	#{
		currently_selected_room.owner = null
		rooms.remove_child(currently_selected_room)
		#print("Room removed from scene tree: " + room_id)
	#}
	else:
		print("Warning: Room is not a child of Rooms node: " + room_id)
	
	# Free the room node
	holding_node.add_child(currently_selected_room)

	# Clear the selected room
	currently_selected_room = null
	#print("Currently selected room cleared.")
	
	# Reset the removal flag
	is_removing_room = false
	#print("Removal process completed.")
	
	AssignInboundRooms()

	# Update inbound links and visuals for remaining rooms
	for room in rooms.get_children():
		room.UpdateInboundVisuals()
		room.UpdateDoorLines()
	
#} // end func _on_remove_room_button_pressed
	
func _on_save_button_pressed():
#{
	#print("Editor map saving room metadata!")  # Your save code goes here

	RebuildRoomsDictionary()

	# wanted to create all the doors before assinging inbounds
	for room in rooms.get_children():
		CreateDoorsFromSpecs( room )

	# assign inbounds before saving any rooms
	AssignInboundRooms()

	for room in rooms.get_children():
	#{
		var filename = room.id + ".meta"
		#print( "metadata filename : ", filename )
		if FileAccess.file_exists( ROOMS_DIR + filename ):
		#{
			#print( "save meta" )
			SaveMetadataForRoom( room, filename )
		#}
		else:
		#{
			#print( "create then save" )
			CreateNewMetaFile( filename )
			SaveMetadataForRoom( room, filename )
		#}
			
		filename = room.id + ".json"
		SaveRoomDataForRoom( room, filename )	
		
		#print( "Current id = " + room.id + ", Original id = " + room.original_id )
		if( room.id != room.original_id ):
		#{
			#print( "Id's are not the same deleting old files")
			var old_json_path = ROOMS_DIR + room.original_id + ".json"
			if( FileAccess.file_exists( old_json_path ) ):
				DirAccess.open( ROOMS_DIR ).remove( old_json_path )
			var old_meta_path = ROOMS_DIR + room.original_id + ".meta"
			if( FileAccess.file_exists( old_meta_path ) ):
				DirAccess.open( ROOMS_DIR ).remove( old_meta_path )
			room.original_id = room.id	
			
		#}  // end if( room.id...
		#else:
			#print( "id's are the same, so no need to delete anything.")

		#print( "-----" )
		
	#} // end for

	# Reselect the node after saving
	if currently_selected_room:
	#{
		var editor_selection = EditorInterface.get_selection()
		editor_selection.clear()
		editor_selection.add_node( currently_selected_room )
		#print( "Reselected room: " + currently_selected_room.label + "." )
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
	#print("EditorMap._ready: Starting")
	#if rooms:
		#print("  Rooms node has ", rooms.get_child_count(), " children")
	#	for child in rooms.get_children():
			#print("    Child: ", child.name, " (Type: ", child.get_class(), ")")
	#else:
		#print("  Rooms node is null")
	holding_node.name = "HoldingNode"
	get_tree().root.add_child(holding_node)
	holding_node.set_owner(null)
	if Engine.is_editor_hint():
		#print("  Editor mode: has_loaded_rooms = ", has_loaded_rooms)
		if not has_loaded_rooms:
			#print("  Calling LoadAllRooms")
			LoadAllRooms()
			has_loaded_rooms = true
		#else:
			#print("  Skipping LoadAllRooms")
	#print("EditorMap._ready: Finished")
	
#func _enter_tree():
	#print("EditorMap._enter_tree: Starting")
	#if rooms:
		#print("  Rooms node has ", rooms.get_child_count(), " children")
	#	for child in rooms.get_children():
			#print("    Child: ", child.name, " (Type: ", child.get_class(), ")")
	#else:
		#print("  Rooms node is null")
	#print("EditorMap._enter_tree: Finished")

func AddRoomToEditorMap(room):
	#print("AddRoomToEditorMap: Starting for room: ", room.id if room else "null")
	#print("  Stack: ", get_stack())
	if not room:
		print("  Error: Room is null")
		return
	#print("  Adding room to 'rooms' node")
	rooms.add_child(room)
	#print("    Room added. Parent: ", room.get_parent().name if room.get_parent() else "null")
	#print("  Setting room owner to edited scene root")
	room.owner = get_tree().edited_scene_root
	#print("    Room owner set to: ", room.owner.name if room.owner else "null")
	#print("  Processing room children for doors")
	#var door_count = 0
	for door in room.get_children():
		#print("    Child found: ", door.name, " (Type: ", door.get_class(), ")")
		if door is Door:
			#door_count += 1
			#print("      Door detected: ", door.name, " (ID: ", door.id, ", Destination: ", door.destination, ")")
			#print("        Is inside tree: ", door.is_inside_tree())
			#print("        Parent: ", door.get_parent().name if door.get_parent() else "null")
			#print("        Owner: ", door.owner.name if door.owner else "null before setting")
			door.owner = get_tree().edited_scene_root
			#print("        Owner set to: ", door.owner.name if door.owner else "null")
			#if door.is_inside_tree() and door.get_parent() == room:
			#	print("        Locking door: ", door.name, " in room: ", room.id)
			#else:
			#	print("Warning: Door ", door.name, " not in scene tree or wrong parent")
		#else:
		#	print("      Not a Door: ", door.name)
	#print("    Total doors processed: ", door_count)
	# Rebuild the doors array from children
	room.doors.clear()
	for child in room.get_children():
		if child is Door:
			room.doors.append(child)
	#print("    Doors array rebuilt: ", room.doors.size(), " doors")
	#print("  Setting editor_map reference")
	room.editor_map = self
	#print("    editor_map set to: ", room.editor_map.name if room.editor_map else "null")
	#print("  Calling SetupVisuals for room: ", room.id)
	room.SetupVisuals()
	#print("  SetupVisuals completed for room: ", room.id)
	#print("AddRoomToEditorMap: Finished for room: ", room.id)
	
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
			#print( "Meta file created successfully." )
		#else:
			#print( "Meta file could not be created." )
		
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
			#print( "Room position x: " + str( room.position.x ) + ", y: " + str( room.position.y ) + " ...saved." )
		else:
			print( "Couldn't open file for writing." )
	else:
		CreateNewMetaFile( filename )
		
#} // end func SaveMetadataForRoom()

func CreateDoorsFromSpecs( room ):
	#print( "--- Running CreateDoorsFromSpecs()" )
	var doors = room.doors.duplicate()
	room.doors.clear()
	for door in doors:
		if door and door.get_parent() == room:
			#print("Removing " + door.id + " from room " + room.id)
			door.owner = null
			room.remove_child(door)
			door.queue_free()
	
	var id_str = "***_***"
	var choice_str = "*"
	var dest_str = "***_***"
	
	#print("***\n")
	var hue = 0.0
	for doorspec in room.door_specs:
		if doorspec == "":
			continue
		
		id_str = "***_***"
		choice_str = "*"
		dest_str = "***_***"
		
		var i = 0
		var dlen = doorspec.length()
		
		if doorspec.begins_with("ch: "):
			i = 4
			choice_str = ""
			while i < dlen and doorspec[i] != ',':
				choice_str += doorspec[i]
				i += 1
			i += 1
			if doorspec.substr(i).begins_with(" dest: "):
				i += 7
				dest_str = ""
				while i < dlen and doorspec[i] != ';':
					dest_str += doorspec[i]
					i += 1
					
		id_str = "Door_To_" + dest_str.substr(4)
		#print("*//* id: " + id_str + ", choice: " + choice_str + ", dest: " + dest_str)
		
		#print( "ccc" )
		var color = Color.from_hsv( hue, 0.8, 1.0 )
		hue += 1.0 / 9
		#print( "Color = ", color )
		#print( "ccc" )
		var new_door = Door.create( id_str, choice_str, dest_str, id_str, color )
		if new_door:
			room.doors.append(new_door)
			room.add_child(new_door)
			new_door.owner = get_tree().edited_scene_root
			#room.set_editable_instance(new_door, false) # Lock door in editor viewport
			#print("Successfully created door: ", new_door.name)
		#else:
		#	print("Failed to create door for spec: ", doorspec)
	
	var door = null
	var spec_str = ""
	for i in range(9):
		if i < room.doors.size():
			door = room.doors[i]
			if door != null:
				spec_str = "ch: " + door.choice + ", dest: " + door.destination + ";"
			else:
				spec_str = ""
		else:
			spec_str = ""
		room.door_specs[i] = spec_str
	
	room.emit_signal("property_list_changed")
	#print("\n***")

func SaveRoomDataForRoom(room, filename: String):
#{
	#print("*Save Room Data*")	
	var jsonpath = ROOMS_DIR + filename
	#print("Saving room data to: ", jsonpath)
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
	#print( "Checking for metadata for ", filename )
	var metapath = filename.replace(".json", ".meta")
	metapath = "res://Rooms/" + metapath
	if FileAccess.file_exists( metapath ):
		var file = FileAccess.open( metapath, FileAccess.READ )
		var meta_data = JSON.parse_string( file.get_as_text() )
		file.close()
		if meta_data:
			room.position.x = meta_data[ "x" ]
			room.position.y = meta_data[ "y" ]
			#print( "Room position x: " + str( room.position.x ) + ", y: " + str( room.position.y ) )
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
	#print("Visiting room: ", room.id)
	# Visit all rooms that depend on this room (via inbound_rooms)
	for inbound_id in room.inbound_rooms:
		if inbound_id != "" and rooms_dict.has(inbound_id):
			var source_room = rooms_dict[inbound_id]
			#print("  Source room that depends on this: ", source_room.id)
			_visit_room(source_room, sorted_rooms, visited, temp_visited)
	temp_visited.erase(room.id)
	visited[room.id] = true
	sorted_rooms.push_front(room)
	#print("Added to sorted list: ", room.id)
	
func topological_sort_rooms() -> Array:
	var sorted_rooms = []
	var visited = {}
	var temp_visited = {}

	for room in rooms.get_children():
		if not (room.id in visited):
			_visit_room(room, sorted_rooms, visited, temp_visited)
	#print("Sorted rooms order: ", sorted_rooms.map(func(r): return r.id))
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
				#print("---")
				#print("Next json in file list: ", item)
				var json_name = filename.replace(".json", "")
				var room = Room.CreateFromJSON(json_name)
				if room:
					rooms_dict[ room.id ] = room
					AddRoomToEditorMap(room)
					LoadMetadataForRoom(room, filename)
				if filename.begins_with("003"):
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
		if room is Room:
			previous_positions[room.id] = room.position
	
	#print("***")

func _exit_tree():
	#print("EditorMap._exit_tree: Cleaning up")
	# Clear Rooms node
	if rooms:
		#print("  Clearing Rooms node with ", rooms.get_child_count(), " children")
		for room in rooms.get_children():
			if room is Room:
				#rint("    Processing room: ", room.id, " (Label: ", room.label, ")")
				# Clear room's children (e.g., Door nodes)
				var child_count = room.get_child_count()
				if child_count > 0:
					#print("      Clearing ", child_count, " children of room: ", room.id)
					for child in room.get_children():
						#print("        Removing child: ", child.name, " (Type: ", child.get_class(), ")")
						room.remove_child(child)
						child.queue_free()
				#else:
					#print("      No children in room: ", room.id)
				# Remove the room
				#print("    Removing room: ", room.id)
				rooms.remove_child(room)
				room.queue_free()
			else:
				#print("    Removing non-room child: ", room.name)
				rooms.remove_child(room)
				room.queue_free()
	else:
		print("  Rooms node not found")
		
	# Existing cleanup for holding_node
	if holding_node:
		#print("  Clearing holding_node with ", holding_node.get_child_count(), " children")
		for child in holding_node.get_children():
			#print("        Removing holding_node child: ", child.name)
			child.queue_free()
		holding_node.queue_free()
		holding_node = null
	#print("EditorMap._exit_tree: Finished")
	
	# Dictionary to store previous positions of rooms
var previous_positions: Dictionary = {}

func update_lines_for_room_and_dependents(room: Node) -> void:
	# Update lines for this room (outbound lines)
	room.UpdateDoorLines()
	
	# Update lines for all rooms that have this room as a destination (inbound lines)
	for other_room in rooms.get_children():
		if other_room != room and other_room is Room:
			for door in other_room.doors:
				if door.destination == room.id:
					other_room.UpdateDoorLines()
					break
					
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		for room in rooms.get_children():
			if room is Room:
				var current_pos = room.position
				var room_id = room.id
				if previous_positions.has(room_id):
					if previous_positions[room_id] != current_pos:
						#print("Position changed for room: ", room_id, " from ", previous_positions[room_id], " to ", current_pos)
						# Update lines for this room and all rooms that link to itScreenshot from 2025-05-09 13-00-33
						update_lines_for_room_and_dependents(room)
				previous_positions[room_id] = current_pos
