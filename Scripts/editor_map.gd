@tool
extends Node

# Flag to prevent load_all_rooms from running multiple times
var has_loaded_rooms: bool = false
@onready var rooms = $Rooms

const ROOMS_DIR = "res://Rooms/"

func ToKebabCase( pascal_name: String ) -> String:
	var result = ""
	for i in range( pascal_name.length() ):
		var ch = pascal_name[ i ]
		
		if i > 0 and ( ch >= 'A' and ch <= 'Z' ):
			result += "-"
		result += ch.to_lower()
	return result
	
func _on_save_button_pressed():
#{
	print("Editor map saving room metadata!")  # Your save code goes here
	for room in rooms.get_children():
	#{
		var filename = room.id + ".meta"
		print( "metadata filename : ", filename )
		if FileAccess.file_exists( ROOMS_DIR + filename ):
		#{
			print( "save meta" )
			SaveMetadataForRoom( room, filename )
		#}
		else:
		#{
			print( "create then save" )
			CreateNewMetaFile( filename )
			SaveMetadataForRoom( room, filename )
		#}
						
		filename = room.id + ".json"
		print( "save room" )
		CreateDoorsFromSpecs( room )
		SaveRoomDataForRoom( room, filename )	
		
		print( "Current id = " + room.id + ", Original id = " + room.original_id )
		if( room.id != room.original_id ):
			print( "Id's are not the same deleting old files")
			var old_json_path = ROOMS_DIR + room.original_id + ".json"
			if( FileAccess.file_exists( old_json_path ) ):
				DirAccess.open( ROOMS_DIR ).remove( old_json_path )
			var old_meta_path = ROOMS_DIR + room.original_id + ".meta"
			if( FileAccess.file_exists( old_meta_path ) ):
				DirAccess.open( ROOMS_DIR ).remove( old_meta_path )
			room.original_id = room.id	
		else:
			print( "id's are the same, so no need to delete anything.")

		print( "-----" )
		
	#} // end for
	
#} // end func _on_save_button_pressed()
	
func _ready():
	print( "***" )
	print( "EDITOR MAP READY" )
	if Engine.is_editor_hint():
		if not has_loaded_rooms:
			LoadAllRooms()
			has_loaded_rooms = true

# end func _ready()

func AddRoomToEditorMap( room ):
	rooms.add_child( room )
	room.owner = get_tree().edited_scene_root
	for door in room.get_children():
		if door is Door:
			door.owner = get_tree().edited_scene_root
	room.editor_map = self
	room.SetupVisuals()  

func CreateNewMetaFile( filename ):
	print( "*Create*" )
	var metaname = filename
	if( filename.ends_with( ".json" ) ): 
		metaname = filename.replace(".json", ".meta")
	if not FileAccess.file_exists( ROOMS_DIR + metaname ):
		var meta_file = FileAccess.open( ROOMS_DIR + metaname, FileAccess.WRITE )
		if FileAccess.get_open_error() == OK:
			var meta_data = {"x": 0, "y": 0}
			meta_file.store_string( JSON.stringify( meta_data ) )
			meta_file.close()
			print( "Meta file created successfully." )
		else:
			print( "Meta file could not be created." )
		
# end func LoadMetadataForRoom()

func SaveMetadataForRoom( room, filename ):
	print( "*Save*" )
	var metapath = ROOMS_DIR + filename
	if FileAccess.file_exists( metapath ):
		var file = FileAccess.open( metapath, FileAccess.WRITE )
		if FileAccess.get_open_error() == OK:
			var meta_data = {"x": room.position.x, "y": room.position.y}
			file.store_string( JSON.stringify( meta_data ) )
			file.close()
			print( "Room position x: " + str( room.position.x ) + ", y: " + str( room.position.y ) + " ...saved." )
		else:
			print( "Couldn't open file for writing." )
	else:
		print( "SaveMetadataForRoom()" )
		CreateNewMetaFile( filename )
		
# end func SaveMetadataForRoom()

func CreateDoorsFromSpecs(room):
#{
	var doors = room.doors.duplicate()  # Create a copy to avoid iteration issues
	room.doors.clear()
	for door in doors:
		if door and door.get_parent() == room:  # Ensure door is still a child
			print("Removing " + door.id + " from room " + room.id)
			door.owner = null  # Unset owner to help editor recognize removal
			room.remove_child(door)
			door.queue_free()
	
	var id_str = ""
	var choice_str = ""
	var dest_str = ""
	
	print("***\n")
	for doorspec in room.door_specs:
	#{
		if !doorspec.ends_with(";"):
			continue
			
		var i = 0
		var dlen = doorspec.length()

		# Parse "ch: <choice>"
		if doorspec.begins_with("ch: "):
			i = 4  # Skip "ch: "
			choice_str = ""
			while i < dlen and doorspec[i] != ',':
				choice_str += doorspec[i]
				i += 1
			i += 1  # Skip the comma

			# Parse ", dest: <destination>"
			if doorspec.substr(i).begins_with(" dest: "):
				i += 7  # Skip ", dest: "
				dest_str = ""
				while i < dlen and doorspec[i] != ';':
					dest_str += doorspec[i]
					i += 1
					
		id_str = "Door_To_" + dest_str.substr(4)
		
		var new_door = Door.create(id_str, choice_str, dest_str, id_str)
		if new_door:
			room.doors.append(new_door)
			room.add_child(new_door)
			new_door.owner = get_tree().edited_scene_root  # Set owner for editor visibility
			print("Successfully created door: ", new_door.name)
		else:
			print("Failed to create door for spec: ", doorspec)

	#}  // end for doorspec

	var door = null
	var spec_str = ""
	for i in range( 9 ):
		if( i < room.doors.size() ):
			door = room.doors[ i ]
			if( door != null ):
				spec_str = "ch: " + door.choice + ", dest: " + door.destination + ";"
			else:
				spec_str = ""
		else:
			spec_str = ""
		room.door_specs[ i ] = spec_str
	
	room.emit_signal("property_list_changed")  # Notify the editor to refresh the Inspector

	print("\n***")
	
#} // func CreateDoorsFromSpecs()

func SaveRoomDataForRoom(room, filename: String):
	print("*Save Room Data*")
	var jsonpath = ROOMS_DIR + filename
	print("Saving room data to: ", jsonpath)
	var file = FileAccess.open(jsonpath, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		# Manually construct the JSON string with the desired order
		var json_str = "{\n"
		json_str += '    "id": ' + JSON.stringify(room.id) + ",\n"
		json_str += '    "parent": ' + JSON.stringify(room.origin) + ",\n"
		json_str += '    "label": ' + JSON.stringify(room.label) + ",\n"
		json_str += '    "description": ' + JSON.stringify(room.description) + ",\n"
		json_str += '    "doors": [\n'

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
		print("Room data saved for: ", filename)
	else:
		print("Couldn't open file for writing: ", jsonpath)
		
func LoadMetadataForRoom( room, filename ):
	print( "Checking for metadata for ", filename )
	var metapath = filename.replace(".json", ".meta")
	metapath = "res://Rooms/" + metapath
	if FileAccess.file_exists( metapath ):
		var file = FileAccess.open( metapath, FileAccess.READ )
		var meta_data = JSON.parse_string( file.get_as_text() )
		file.close()
		if meta_data:
			room.position.x = meta_data[ "x" ]
			room.position.y = meta_data[ "y" ]
			print( "Room position x: " + str( room.position.x ) + ", y: " + str( room.position.y ) )
		else:
			print( "No meta data read." )
		
# end func LoadMetadataForRoom()

func LoadAllRooms():
	print("Running load_all_rooms")
	for child in rooms.get_children():
		rooms.remove_child( child )
		child.queue_free()

	# Step 1: Load all rooms into a dictionary
	var filelist = []
	var filename = ""

	# Load .json files
	filelist = []
	filename = ""
	var json_dir = DirAccess.open("res://Rooms/")
	if json_dir:
		filelist = json_dir.get_files()
		for item in filelist:
			filename = item
			if filename.ends_with( ".json" ):
				print("---")
				print( "Next json in file list: ", item )
				var json_name = filename.replace(".json", "")
				var room = Room.CreateFromJSON(json_name)
				if room:
					AddRoomToEditorMap( room )
					LoadMetadataForRoom( room, filename )
					
				if filename.begins_with("004_Caves"):
					break

	print( "***" )
	
#func _process(delta):
#	if Engine.is_editor_hint():  # Ensure it only runs in editor
#		var canvas_offset = get_viewport().canvas_transform.origin
#		save_button.position = Vector2( 10, 10 ) - canvas_offset
#		print(canvas_offset)
#		for room in get_children():
#			var last_pos = room.get_meta("last_pos", Vector2.ZERO)
#			if room.position != last_pos:
#				print(room.name, " moved to: ", room.position)
#				room.set_meta("last_pos", room.position)
