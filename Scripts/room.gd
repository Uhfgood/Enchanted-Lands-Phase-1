class_name Room extends Node2D
@export var id : String = "rmXXX"

@export var room_name : String = "blank_room"
@export_multiline var description : String = "Modify the description text to describe your scene, and add your choices.  Make sure to number your choices up to 9, and add 0 for Exit."

var doors : Array[ Door ] = []

# Convert snake_case to PascalCase (e.g., "hotel_max_stash" -> "HotelMaxStash")
func ToPascalCase( snake: String ) -> String:
	var words = snake.split("-")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word.capitalize()
	return result
	
func LoadDataFromJSON( json_name : String )->bool:
	var filename = "res://Rooms/json_data/" + json_name + ".json"
	
	if not FileAccess.file_exists( filename ):
		print( filename + " does not exist." )
		
	# load the json here:
	var file = FileAccess.open( filename, FileAccess.READ )
	if not file:
		print( "Error loading file from json: " + filename )
		return false
		
	# parse json
	var json_data = JSON.parse_string( file.get_as_text() )
	file.close()
	if json_data == null:
		print( "Error parsing JSON data: " + filename )
		return false
		
	# set room properties
	self.id = json_data[ "id" ]
	self.room_name = json_data[ "name" ]
	self.name = self.id + "-" + ToPascalCase( self.room_name )
	self.description = json_data[ "description" ]
	
	# create and attach door nodes
	if "doors" in json_data:
		for door_data in json_data[ "doors" ]:
			var new_door = Door.create( 
				door_data[ "id" ], door_data[ "choice" ], door_data[ "destination"] )
			if new_door:
				doors.append( new_door )
				add_child( new_door )
			else:
				print( "New door not valid." )
			
	return true
	
static func CreateFromJSON( json_name : String )->Room:
	var new_room = Room.new()
	
	if new_room.LoadDataFromJSON( json_name ) == false:
		return null
				
	return new_room
	
func GetDoorByChoice( choice : String ) -> Door:
	for door in doors:
		if( door.choice == choice ):
			return door
	
	return null
