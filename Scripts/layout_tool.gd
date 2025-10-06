@tool
class_name LayoutTool extends Node

var is_removing_room: bool = false

# Flag to prevent load_all_rooms from running multiple times
static var has_loaded_rooms = false

@onready var layout_tool = $"."
@onready var rooms = $Rooms

var line_overlay = null

var currently_selected_room = null

const ROOMS_DIR = "res://Rooms/"
const LAYOUT_TOOL_DATA_DIR = "res://LayoutToolData/"
const ROOM_EXT = ".json"
const META_EXT = ".metadata.json"

var camera : Camera2D = null;

var current_highest_z_index = 0;

var rooms_dict = {};
var removed_rooms : Array[String] = [];

func GetRoomChildren() -> Array:
#{
	var room_children = [];
	for child in rooms.get_children():
		if( child is LayoutRoom ):
			room_children.append( child );
	return( room_children );
#}

# At the top of layout_tool.gd, add:
var holding_node: Node = Node.new()

func _on_selection_changed():
#{
	if( !Engine.is_editor_hint() ):
		return

	print( "_on_selection_changed executed" )
	
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
			if(selected_node is LayoutRoom):
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
	for child in GetRoomChildren():
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
	print( "---" );
	var unique_label = get_unique_room_label( "New Location" );
	var new_id = "000_" + unique_label.replace( " ", "_" );
	var new_label = unique_label;
	var new_desc = "There's nothing here yet.  Hit 0 to quit.";
	var new_room = LayoutRoom.Create( new_id, new_label, new_desc );
	if( new_room ):
		current_highest_z_index += 1;
		new_room.z_index = current_highest_z_index;
	
	#new_room.SetupVisuals()
	AddRoomToLayoutTool( new_room )
	
	if( Engine.is_editor_hint() ):
	#{
		# Select the new room in the scene tree
		var editor_selection = EditorInterface.get_selection()
		editor_selection.clear()
		editor_selection.add_node( new_room )
		print( "Selected new room: " + new_room.label + "." )
		print( "---" )
	#}
	
#}  // end _on_add_room_button_pressed():

# create a dictionary so I can rebuild inbound list later
func RebuildRoomsDictionary():	
	rooms_dict.clear()
	for room in GetRoomChildren():
		rooms_dict[ room.id ] = room 

func AssignInboundRooms():
#{	
	## Pre-step: clear out all the inbound_rooms arrays
	for room in rooms_dict.values():
		room.ClearInboundRooms()
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
	
	var editor_selection = null
	if( Engine.is_editor_hint() ):
	#{
		# Disconnect the selection_changed signal to prevent it from firing during removal
		editor_selection = EditorInterface.get_selection()
		if editor_selection.is_connected("selection_changed", Callable(self, "_on_selection_changed")):
			editor_selection.disconnect("selection_changed", Callable(self, "_on_selection_changed"))
		# Clear the editor's selection
		editor_selection.clear()
	#}
		
	
	# Get the room's ID to locate the files
	var room_id = currently_selected_room.roomdata.id
	if room_id == "":
		print("Room " + currently_selected_room.label + " has no ID; removing from scene only.")
	else:
		removed_rooms.append(room_id)
	
	currently_selected_room.RemoveChildren()
	
	# Remove the room from the scene tree safely #
	if currently_selected_room.get_parent() == rooms:
	#{
		currently_selected_room.owner = null
		rooms.remove_child( currently_selected_room )
	#}
	else:
		print("Warning: Room is not a child of Rooms node: " + room_id)
	
	# Free the room node
	holding_node.add_child( currently_selected_room )

	# Clear the selected room
	currently_selected_room = null
	
	# Reset the removal flag
	is_removing_room = false
	
	RebuildRoomsDictionary()
	
	AssignInboundRooms()
	
	print( "Removed room: ", room_id )
	
	if( Engine.is_editor_hint() ):
	#{
		# Synchronous reconnection
		if not editor_selection.is_connected("selection_changed", Callable(self, "_on_selection_changed")):
			editor_selection.connect("selection_changed", Callable(self, "_on_selection_changed"))
			print("Reconnected selection_changed signal")
	#}
				
	#for child in holding_node.get_children():
	#	holding_node.remove_child(child)
	#	child.queue_free()
		
	#print("Holding node children: ", holding_node.get_child_count())
	
#} // end func _on_remove_room_button_pressed
	
func _on_save_button_pressed():
#{
	self.SaveProjectFile( project_filename );
	
	RebuildRoomsDictionary();

	# wanted to create all the doors before assinging inbounds
	for room in GetRoomChildren():
		room.CreateDoorsFromSpecs();

	# assign inbounds before saving any rooms
	AssignInboundRooms();

	for room in GetRoomChildren():
	#{
		var filename = room.id + META_EXT
		SaveMetadataForRoom( room, filename );

		filename = room.id + ROOM_EXT
		SaveRoomDataForRoom( room, filename );
		
		if( room.id != room.original_id ):
		#{
			var old_json_path = ROOMS_DIR + room.original_id + ROOM_EXT;
			if( FileAccess.file_exists( old_json_path ) ):
				DirAccess.open( ROOMS_DIR ).remove( old_json_path );
			var old_meta_path = LAYOUT_TOOL_DATA_DIR + room.original_id + META_EXT;
			if( FileAccess.file_exists( old_meta_path ) ):
				DirAccess.open( LAYOUT_TOOL_DATA_DIR ).remove( old_meta_path );
			room.original_id = room.id;
			
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
		var json_path = ROOMS_DIR + room_id + ROOM_EXT #".json"
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
		var meta_path = LAYOUT_TOOL_DATA_DIR + room_id + META_EXT #".meta"
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
	
	#line_overlay.UpdateAllLines();
	line_overlay.UpdateAllLines( 2.0 / current_zoom_level );
	
#} // end func _on_save_button_pressed()

#func _notification(what):
	#if what == NOTIFICATION_EDITOR_PRE_SAVE:
		#print("Editor pre-save, clearing Rooms to prevent saving")
		#if rooms:
			#for room in GetRoomChildren():
				#rooms.remove_child(room)
				#room.queue_free()
		## Trigger reload after save
		#var scene_path = EditorInterface.get_edited_scene_root().get_scene_file_path()
		#if scene_path:
			#print("Triggering reload of scene: ", scene_path)
			#call_deferred("reload_scene", scene_path)
#
#func reload_scene(scene_path: String):
	#EditorInterface.reload_scene_from_path(scene_path)
					
func _ready():
	print("LayoutTool _ready, instance:%s, has_loaded_rooms: %s" % [self, has_loaded_rooms])
	if rooms:
		print( "parent= " + rooms.get_parent().name )
		print("Clearing %d rooms in _ready" % rooms.get_child_count())
		for room in GetRoomChildren():
			rooms.remove_child(room)
			room.queue_free()
	if not has_loaded_rooms:
		print("Deferring LoadAllRooms to next idle frame")
		#call_deferred("LoadAllRooms")
		if( get_tree() ):
			call_deferred("LoadAllRooms")
			print( "Call has been deferred." )
		else:
			print( "Tree is invalid" )
			
		has_loaded_rooms = true
		
	rooms.set_meta("_edit_lock_", true)
	if( Engine.is_editor_hint() ):
	#{
		var editor_selection = EditorInterface.get_selection()
		if editor_selection and not editor_selection.is_connected("selection_changed", Callable(self, "_on_selection_changed")):
			editor_selection.connect("selection_changed", Callable(self, "_on_selection_changed"))
			print("Connected selection_changed to EditorSelection")
	#}
	
	# Connect to all existing LayoutRooms
	#for room in GetRoomChildren():
	#	print( "Connecting ", room.name )
	#	_connect_room(room)

	
func _enter_tree():
	print("LayoutTool entering tree, instance:%s" % self)

func _exit_tree():
	#print("LayoutTool exiting tree, instance:%s, Rooms children: %d" % [self, rooms.get_child_count()])
	has_loaded_rooms = false
	if rooms:
		print("Clearing %d rooms in _exit_tree" % rooms.get_child_count())
		for room in GetRoomChildren():
			rooms.remove_child(room)
			room.queue_free()
	
	# Remove the line overlay at the end so it's no longer in the tree until reload
	if( line_overlay ): 
		layout_tool.set_owner( null )
		layout_tool.remove_child(line_overlay)
		line_overlay.queue_free()
		line_overlay = null

	if( Engine.is_editor_hint() ):
	#{
		var editor_selection = EditorInterface.get_selection()
		if editor_selection and editor_selection.is_connected("selection_changed", Callable(self, "_on_selection_changed")):
			editor_selection.disconnect("selection_changed", Callable(self, "_on_selection_changed"))
	#}
	
	if is_instance_valid(holding_node):
		for child in holding_node.get_children():
			child.queue_free()
		if holding_node.get_parent():
			holding_node.get_parent().remove_child(holding_node)
		holding_node.queue_free()
		holding_node = null
	
	if Engine.is_editor_hint():
		return  # Don't save when editor is shutting down
			
	self.SaveProjectFile( project_filename );

func AddRoomToLayoutTool(room: LayoutRoom):
	if not room:
		print("Error: Room is null")
		return
	rooms.add_child(room)
	room.SetOwner(self)
	room.layout_tool = self
	#room.SetupVisuals()

func GetCameraStateJson() -> String:
#{
	var cam_x = 0;
	var cam_y = 0;
	var zoom_x = 1;
	var zoom_y = 1;
	
	if( camera ):
	#{
		cam_x = camera.position.x;
		cam_y = camera.position.y;
		zoom_x = camera.zoom.x;
		zoom_y = camera.zoom.y;
	#}  // end if camera
	
	var data = {
		"position": {
			"x": cam_x,
			"y": cam_y
		},
		"zoom": {
			"x": zoom_x,
			"y": zoom_y
		}
	}
	
	return JSON.stringify(data, "\t")  # Pretty-print with tabs for readability

#}  // end get_camera_state_json()
	
var project_filename = "project.json";
 
func SaveProjectFile( filename ):
#{
	var project_path = LAYOUT_TOOL_DATA_DIR + filename;
	var project_file = FileAccess.open( project_path, FileAccess.WRITE );
	if( FileAccess.get_open_error() == OK ):
		print( "Status of " + project_path + ": " + "ok" )
		project_file.store_string( GetCameraStateJson() );
		project_file.close();

#}  // end SaveProjectFile()
	
func SaveMetadataForRoom( room, filename ):
#{
	var room_x = 0;
	var room_y = 0;
	
	if( room ):
		room_x = room.position.x;
		room_y = room.position.y;
		
	var metapath = LAYOUT_TOOL_DATA_DIR + filename
	var file = FileAccess.open( metapath, FileAccess.WRITE )
	if FileAccess.get_open_error() == OK:
		var meta_data = {"x": room_x, "y": room_y}
		file.store_string( JSON.stringify( meta_data ) )
		file.close()
	else:
		print( "Couldn't open file for writing." )
		
#} // end func SaveMetadataForRoom()

func SaveRoomDataForRoom(room, filename: String):
#{
	var jsonpath = ROOMS_DIR + filename;
	var file = FileAccess.open(jsonpath, FileAccess.WRITE);
	if( FileAccess.get_open_error() == OK ):
	#{
		# Manually construct the JSON string with the desired order
		var json_str = "{\n"
		json_str += '    "id": ' + JSON.stringify(room.id) + ",\n"
		json_str += '    "label": ' + JSON.stringify(room.label) + ",\n"
		json_str += '    "description": ' + JSON.stringify(room.description) + ",\n"
		
		# door data
		json_str += '    "doors":\n'
		json_str += '    [\n'

		var door_strings = []
		for door in room.GetDoorData():
			var door_data = '        {\n'  # Fixed: Removed erroneous "\ LandingPage"
			door_data += '            "id": ' + JSON.stringify( door.id ) + ',\n'
			door_data += '            "choice": ' + JSON.stringify( door.choice ) + ',\n'
			door_data += '            "destination": ' + JSON.stringify( door.destination ) + '\n'
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
				
		print("Room data saved for: ", filename)
		
	#}  // end if FileAccess
	else:
		print("Couldn't open file for writing: ", jsonpath)
		
#} // end func SaveRoomDataForRoom()

func LoadMetadataForRoom( room, filename ):
#{
	var metapath = filename.replace( ROOM_EXT, META_EXT );
	metapath = LAYOUT_TOOL_DATA_DIR + metapath;
	if FileAccess.file_exists( metapath ):
		var file = FileAccess.open( metapath, FileAccess.READ );
		var meta_data = JSON.parse_string( file.get_as_text() );
		file.close();
		if meta_data:
			room.position.x = meta_data[ "x" ];
			room.position.y = meta_data[ "y" ];
		else:
			print( "No meta data read." );
		
#} // end func LoadMetadataForRoom()

func LoadProjectFile( filename ):
#{
	var metapath = LAYOUT_TOOL_DATA_DIR + filename;
	if FileAccess.file_exists( metapath ):
		var file = FileAccess.open( metapath, FileAccess.READ );
		var meta_data = JSON.parse_string( file.get_as_text() );
		file.close();
		if meta_data:
			if( camera ):
				camera.position.x = meta_data[ "position" ][ "x" ];
				camera.position.y = meta_data[ "position" ][ "y" ];
				camera.zoom.x = meta_data[ "zoom" ][ "x" ];
				camera.zoom.y = meta_data[ "zoom" ][ "y" ];
		else:
			print( "No meta data read." );
		
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

	for room in GetRoomChildren():
		if not (room.id in visited):
			_visit_room(room, sorted_rooms, visited, temp_visited)
	return sorted_rooms

# these are so we can do a box select
var selection_box : Area2D;
var collision_shape : CollisionShape2D;
var selection_color_rect : ColorRect;

func LoadAllRooms():
#{
	#print("Running LoadAllRooms, instance:%s, stack: %s" % [self, get_stack()])
	print( "Running LoadAllRooms" )
	rooms_dict.clear()
	
	for child in GetRoomChildren():
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
			if filename.ends_with( ROOM_EXT ): #".json"):
				var json_name = filename.replace( ROOM_EXT, "" ); #".json", "")
				var room = LayoutRoom.CreateFromJSON(json_name)
				if room:
					#print( "Room: " + room.id + " created.")
					current_highest_z_index += 1;
					room.z_index = current_highest_z_index;
					rooms_dict[ room.id ] = room
					AddRoomToLayoutTool( room );
					LoadMetadataForRoom( room, filename );
					
				#if filename.begins_with("003"):
				#	break

	# Step 2: Assign inbound rooms for all rooms
	AssignInboundRooms();

	# Step 3: Update visuals for all rooms in dependency order
	#var sorted_rooms = topological_sort_rooms();

	# Step 4: Initialize previous positions
	for room in GetRoomChildren():
		if room is LayoutRoom:
			room.previous_position = room.position;
			_connect_room( room )
	
	#for room in rooms_dict.values():
	#	print(room.name, room.position);
	
	var existing_overlay = layout_tool.find_child( "LineOverlay" );
	if( existing_overlay ):
		print( "overlay already exists, removing" );
		layout_tool.remove_child( existing_overlay );
		
	line_overlay = MultiLine2D.new();
	line_overlay.set_meta("_edit_lock_", true);
	line_overlay.position = rooms.position;
	layout_tool.add_child( line_overlay );
	line_overlay.name = "LineOverlay";
	line_overlay.set_owner( self );
	line_overlay.InitLines( rooms_dict );

	var existing_camera = layout_tool.find_child( "LayoutCamera" );
	if( existing_camera ):
		print( "camera already exists, removing" );
		layout_tool.remove_child( existing_camera );
	
	camera = LayoutCamera.new();
	layout_tool.add_child( camera );
	camera.make_current();
	camera.name = "LayoutCamera";
	camera.set_owner( self );
	camera.room_container = rooms
	camera._update_min_zoom()

	if( camera ):
		LoadProjectFile( project_filename );
	else:
		print( "Camera not initialized" );

	# created collision shape and area2d at the class level (above this function)
	selection_box = Area2D.new();
	collision_shape = CollisionShape2D.new();
	collision_shape.shape = RectangleShape2D.new();
	selection_box.add_child( collision_shape );
	rooms.add_child( selection_box );

	# Create the visible rectangle for the drag box
	selection_color_rect = ColorRect.new();
	selection_color_rect.color = Color( 0.3, 0.6, 1, 0.3 );  # Semi-transparent blue
	selection_color_rect.position = Vector2.ZERO;       # Start at origin
	selection_color_rect.size = Vector2( 500, 500 ); #Vector2.ZERO;           # Start with zero size
	selection_color_rect.visible = true;
	rooms.add_child(selection_color_rect)                  # Add to rooms container

	print( "End of LoadAllRooms" );
	
#}  // end LoadAllRooms

func UpdateOverlay():
#{
	for room in rooms.get_children():
	#{
		if room is LayoutRoom:
			if( room.previous_position != room.position ):
				line_overlay.UpdateLines( room.id );
				room.previous_position = room.position;
				
	#}  // end for room
	
#}  // end func UpdateLines()

var last_zoom_level : float = 1.0;
var line_thickness : float = 5.0;
var current_zoom_level = 2.0

func HandleZoom( ):
#{
	current_zoom_level = get_viewport().get_final_transform().x.x;
	
	if( not Engine.is_editor_hint() ):
		if( camera ):
			current_zoom_level = camera.zoom.x;
			
	last_zoom_level = current_zoom_level;
	line_thickness = 2.0 / current_zoom_level;
	if( line_overlay ):
		line_overlay.UpdateAllLines( line_thickness );

#}  // end HandleZoom()

func _process(_delta: float) -> void:
	UpdateOverlay();
	HandleZoom();
	
	if( not Engine.is_editor_hint() ):
		if( camera ):
			pass
			
func _connect_room(room: LayoutRoom) -> void:
	room.connect("clicked", Callable(self, "_on_room_clicked"))

func GetMousePosition() -> Vector2:
#{
	#var mouse_pos = camera.get_viewport().get_mouse_position()
	#var mouse_local = rooms.to_local(mouse_pos)
	
	var mouse_local = Vector2.ZERO;
	
	if( camera ):
	#{
		var viewport_mouse_pos = camera.get_viewport().get_mouse_position();
	#}
	else:
		print( "Warning: camera non-existant, defaulting to ZERO" );
		
	return mouse_local;

#}  // end GetMousePosition

var drag_start_pos := Vector2.ZERO

# Currently selected rooms
var selected_rooms: Array[LayoutRoom] = []

# Simulate dragging state
var is_dragging: bool = false

var pending_room_click : LayoutRoom = null;
var pending_shift : bool = false;
var pending_ctrl : bool = false;

func _on_room_clicked(room: LayoutRoom, shift: bool, ctrl: bool):
#begin
	pending_room_click = room;
	pending_shift = shift;
	pending_ctrl = ctrl;
#end; { func _on_room_clicked()

func ProcessSingleClick(room: LayoutRoom, shift: bool, ctrl: bool):
#{
	room.was_clicked = true;  # mark that this room got clicke
	
	if( shift ):
		if not selected_rooms.has(room):
			selected_rooms.append(room);
			room.is_selected = true;
			room.UpdateHighlight();
	elif( ctrl ):
		if( selected_rooms.has(room) ):
			selected_rooms.erase(room);
			room.is_selected = false;
			room.UpdateHighlight();
		else:
			selected_rooms.append(room);
			room.is_selected = true;
			room.UpdateHighlight();
	else:
		print("Clicked room:", room, "Selected rooms:", selected_rooms)
		for r in selected_rooms:
			print("   contains:", r, r == room);

		# Normal click: clear all others only if the clicked room is not already selected
		if( not selected_rooms.has(room) ):
			_clear_selection();  # your helper function
			selected_rooms.append(room);
			room.is_selected = true;
			room.UpdateHighlight();

	# Start drag if clicked on selected room
	if( selected_rooms.has(room) ):
		is_dragging = true;
		drag_start_pos = GetMousePosition();
		print("Drag started on:", room.name);
		
#}  // end ProcessSingleClick()

# Returns the mouse position relative to the "rooms" node
func get_mouse_in_rooms() -> Vector2:
	# Mouse position in global/world coordinates (accounts for camera)
	var mouse_global = get_viewport().get_mouse_position()
	if camera:
		mouse_global = camera.get_camera_transform().affine_inverse() * mouse_global
	
	# Convert global position to local position relative to the rooms node
	return rooms.to_local(mouse_global)

func _input(event):
	
	# Detect empty-space clicks
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if( camera ):
		#{
			var main_menu_pos = GetRoomChildren()[ 0 ].position;
			var local_mouse_pos = GetMousePosition();
			local_mouse_pos /= camera.zoom
			local_mouse_pos += main_menu_pos;
			print( "local_mouse_pos = " + str( local_mouse_pos ) + ", main menu position = " + str( main_menu_pos ) );
			print( "camera global: ", camera.global_position );
			print( "main_menu global: ", rooms.to_global( main_menu_pos ) );
			print( "mouse viewport coords = ", camera.get_viewport().get_mouse_position() );
			print( "mouse global position = ", camera.get_global_mouse_position() );
			if( selection_color_rect ):
				selection_color_rect.position = camera.global_position;
		#}
		
		var clicked_any_room = false;
		for room in GetRoomChildren():
			if( room.mouse_inside ):
				clicked_any_room = true;
				break;
		if( not clicked_any_room ):
			_clear_selection();
			print( "Clicked empty space: cleared selection" );
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			
		# Drag end
		is_dragging = false
		print("Drag ended")
	
	# Mouse motion drag
	elif event is InputEventMouseMotion and is_dragging:
		#var delta = event.relative / get_zoom() if has_method("get_zoom") else event.relative
		var delta = event.relative;
		if camera:
			delta /= camera.zoom;
		for room in selected_rooms:
			room.position += delta

# Helper to select a room
func _select_room(room: LayoutRoom) -> void:
	selected_rooms.append(room)
	room.is_selected = true
	room.UpdateHighlight()

# Helper to clear all selections
func _clear_selection() -> void:
	for room in selected_rooms:
		room.is_selected = false
		room.UpdateHighlight()
	selected_rooms.clear()
