@tool
class_name Room extends Node2D
@export var id : String = "rmXXX"

@export var room_name : String = "blank_room"
@export_multiline var description : String = "Modify the description text to describe your scene, and add your choices.  Make sure to number your choices up to 9, and add 0 for Exit."

var doors : Array[ Door ] = []

# Flag to prevent _ready from running multiple times
var has_run_ready: bool = false

# Convert snake_case to PascalCase (e.g., "hotel_max_stash" -> "HotelMaxStash")
func ToPascalCase( snake: String ) -> String:
	var words = snake.split("-")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word.capitalize()
	return result
	
# Truncate a string to a max length, adding "..." if truncated
func TruncateText(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length) + "..."	

func LoadDataFromJSON( json_name : String )->bool:
	var filename = "res://Rooms/" + json_name + ".json"
	
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
	
func _ready():
	if has_run_ready:
		print("Skipping duplicate _ready for room: ", name)
		return
	
	has_run_ready = true
	print("Running _ready for room: ", name, " id: ", id, " room_name: ", room_name)	
	
	# Create a Panel as the visual base with a border
	var panel = Panel.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(200, 100)  # Set a minimum size for visibility

	# Add a border via a StyleBoxFlat
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # Dark background
	style.border_color = Color(0.8, 0.8, 0.8, 1.0)  # Light gray border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)

	add_child(panel)

	# Create a VBoxContainer to hold the labels
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)

	# Add a Label for the title (room name)
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = name  # Use the node's name (e.g., "rm000-Welcome")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Add a Label for the truncated description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = TruncateText(description, 50)  # Truncate to 50 characters
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Enable word wrapping
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)
