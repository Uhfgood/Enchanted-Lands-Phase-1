@tool
extends Node2D

# Flag to prevent load_all_rooms from running multiple times
var has_loaded_rooms: bool = false

func _ready():
	print( "***" )
	print( "EDITOR MAP READY" )
	if Engine.is_editor_hint():
		if not has_loaded_rooms:
			LoadAllRooms()
			has_loaded_rooms = true
# end func _ready()

func AddRoomToEditorMap( room ):
	add_child( room )
	room.owner = get_tree().edited_scene_root
	for door in room.get_children():
		if door is Door:
			door.owner = get_tree().edited_scene_root
	room.editor_map = self
	room.SetupVisuals()  
	
func LoadMetadataForRoom( filename ):
	print( "Checking for metadata for ", filename )
		
func LoadAllRooms():
	print("Running load_all_rooms")
	for child in get_children():
		remove_child(child)
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
					LoadMetadataForRoom( filename )
					
				if filename.begins_with("lv005"):
					break

	print( "***" )
