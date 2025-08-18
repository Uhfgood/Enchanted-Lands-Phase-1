class_name Room extends Resource

# Reference to the editor_map node (set by editor_map.gd)
#var editor_map: Node = null

@export var id : String = "XXX" : set = _set_id
func _set_id(new_id: String) -> void:
	id = new_id
	var tokens = new_id.split("_")
	var new_label = ""
	var size = tokens.size()
	for i in range(1, size):
		if i < size - 1:
			new_label += tokens[i] + " "
		else:
			new_label += tokens[i]
	
	self.label = new_label

@export var label : String = "New Room" : set = _set_label
func _set_label(new_label: String) -> void:
	label = new_label

@export_multiline var description : String = "Modify the description text to describe your scene, and add your choices.  Make sure to number your choices up to 9, and add 0 for Exit." : set = _set_description
# Setter for description
func _set_description(new_description: String) -> void:
	description = new_description

var doors : Array = []

var original_id : String = "XXX"

func LoadDataFromJSON( json_name : String ) -> bool:
#{
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
	self.original_id = self.id
	
	#if( "inbound" in json_data ):
	#{
		#var i = 0;
		#for inbound_data in json_data[ "inbound" ]:
		#{
			#if( i < self.inbound_rooms.size() ):
			#{
				#self.inbound_rooms[ i ] = inbound_data
				#i += 1
				#
			#}  // end if i < size
				#
		#}  // end for inbound_data
		#
	#}  // end if "inbound" in json_data
	
	self.label = json_data[ "label" ]
	self.description = json_data[ "description" ]
	
	# create and attach door nodes
	if "doors" in json_data:
	#{
		#var i = 0
		for door_data in json_data[ "doors" ]:
		#{
			var door_id = door_data[ "id" ]
			var choice = door_data[ "choice" ] 
			var dest = door_data[ "destination" ]
			#var door_name = "Door_To_" + dest.substr( 4 )
			#print( "Creating " + door_name + " from JSON data." )

			var new_door = Door.create( door_id, choice, dest ) #, door_name )
			if new_door:
			#{
				doors.append( new_door )
				#add_child( new_door )

				#if( i < 9 ):
					#var spec_str = "ch: " + choice + ", dest: " + dest + ";"
					#door_specs[ i ] = spec_str
					#i += 1
				 
				#print( "Successfully created " + new_door.name + "." )
				
			#}  // end if new_door
			else:
				print( "New door not valid." )
		
		#}  // end for
						
	#}  // end if doors()
	
	return true

#} // end func LoadDataFromJSON()

static func Create( n_id : String, n_label : String, n_desc : String ) -> Room:
#{
	var room = Room.new()
	room.id = n_id
	room.original_id = n_id
	room.label = n_label
	room.description = n_desc
	room.doors = []

	return room
	
#} // end create()
	
static func CreateFromJSON( json_name : String )->Room:
	var new_room = Room.new()
	
	if new_room.LoadDataFromJSON( json_name ) == false:
		return null
				
	return new_room
	
func GetDoorByChoice( choice : String ):
	for door in doors:
		if( door.choice == choice ):
			return door
	
	return null
