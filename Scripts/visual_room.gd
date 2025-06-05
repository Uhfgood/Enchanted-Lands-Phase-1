@tool
class_name VisualRoom extends Node2D

# Reference to the editor_map node (set by editor_map.gd)
var editor_map: Node = null

@export var id : String = "XXX" : set = _set_id
#@export var origin : String = "XXX"
@export var label : String = "New Room" : set = _set_label
@export_multiline var description : String = "Modify the description text to describe your scene, and add your choices.  Make sure to number your choices up to 9, and add 0 for Exit." : set = _set_description

@export var inbound_rooms : Array = [ "", "", "", "", "", "", "", "", "" ]
@export var door_specs : Array = [ "", "", "", "", "", "", "", "", "" ] : set = _set_door_specs
func _set_door_specs( doorspecs : Array ):
	door_specs = doorspecs
	#if Engine.is_editor_hint():
	#	emit_signal("property_list_changed")  # Notify the editor to refresh the Inspector
	
var doors : Array = []
var door_visuals : Array = []
var inbound_visuals : Array = []
var door_lines : Array = []

var original_id : String = "XXX"

var previous_position : Vector2 = Vector2()

# Setter for description
func _set_description(new_description: String) -> void:
	description = new_description
	#if Engine.is_editor_hint():
	update_description_label()

# Update the DescLabel text
func update_description_label() -> void:
	#if not Engine.is_editor_hint():
	#	return  # Safeguard: Only run in the editor

	var desc_label = get_node_or_null("Panel/VBox/DescLabel")
	if desc_label:
		desc_label.text = TruncateText(description, 5, 40)
		desc_label.queue_redraw()  # Ensure the label redraws
		
func _set_id(new_id: String) -> void:
	id = new_id
	var tokens = new_id.split("_")
	#print("Setting id for room: ", name, ", tokens: ", tokens)
	var new_label = ""
	var size = tokens.size()
	for i in range(1, size):
		if i < size - 1:
			new_label += tokens[i] + " "
		else:
			new_label += tokens[i]
	
	self.label = new_label
	#print("New label derived from id: ", new_label)
	
	#if Engine.is_editor_hint():
	if has_node("Panel"):
		update_name_label()
	else:
		#print("Deferring name label update for room: ", name)
		call_deferred("update_name_label", 0, 5)


func _set_label(new_label: String) -> void:
	label = new_label
	#print("setting new label for room: ", name, ", Panel exists: ", has_node("Panel"))
	#if Engine.is_editor_hint():
	if has_node("Panel"):
		update_name_label()
	else:
		#print("Deferring name label update for room: ", name)
		call_deferred("update_name_label", 0, 5)
			
func update_name_label(retry_count: int = 0, max_retries: int = 5) -> void:
	#if not Engine.is_editor_hint():
	#	return

	if not is_inside_tree():  # Safety check: ensure node is in the scene tree
		#print("Room not in scene tree, aborting name label update for: ", name)
		return

	#print("Updating name label for room: ", name, ", retry: ", retry_count)
	var name_label = get_node_or_null("Panel/VBox/NameLabel")
	#print("Attempting to get node at path: Panel/VBox/NameLabel, Result: ", name_label)
	if name_label:
		#print("Got name_label node, setting text to: ", self.label)
		name_label.text = self.label
		name_label.queue_redraw()
	elif retry_count < max_retries:
		#print("NameLabel not found for room: ", name, ", retrying...", retry_count + 1)
		call_deferred("update_name_label", retry_count + 1, max_retries)  # Retry without timer
	else:
		print("Max retries reached, NameLabel still not found for room: ", name)
		
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
	
	if( "inbound" in json_data ):
	#{
		var i = 0;
		for inbound_data in json_data[ "inbound" ]:
		#{
			if( i < self.inbound_rooms.size() ):
			#{
				self.inbound_rooms[ i ] = inbound_data
				i += 1
				
			#}  // end if i < size
				
		#}  // end for inbound_data
		
	#}  // end if "inbound" in json_data
	
	self.label = json_data[ "label" ]
	self.name = self.label
	self.description = json_data[ "description" ]
	#print( "Creating " + self.name + " from JSON data." )
	
	var hue = 0.0
	
	# create and attach door nodes
	if "doors" in json_data:
	#{
		var i = 0
		for door_data in json_data[ "doors" ]:
		#{
			var door_id = door_data[ "id" ]
			var choice = door_data[ "choice" ] 
			var dest = door_data[ "destination" ]
			var door_name = "Door_To_" + dest.substr( 4 )
			#print( "Creating " + door_name + " from JSON data." )

			var color = Color.from_hsv( hue, 0.8, 1.0 )
			hue += 1.0 / 9
			
			var new_door = VisualDoor.create( door_id, choice, dest, door_name, color )
			if new_door:
			#{
				doors.append( new_door )
				add_child( new_door )

				if( i < 9 ):
					var spec_str = "ch: " + choice + ", dest: " + dest + ";"
					door_specs[ i ] = spec_str
					i += 1
				 
				#print( "Successfully created " + new_door.name + "." )
				
			#}  // end if new_door
			else:
				print( "New door not valid." )
		
		#}  // end for
						
	#}  // end if doors()
	
	return true

#Th} // end func LoadDataFromJSON()

static func Create( n_id : String, n_label : String, n_desc : String ) -> VisualRoom:
#{
	var room = VisualRoom.new()
	room.id = n_id
	room.original_id = n_id
	#room.origin = n_origin
	room.label = n_label
	room.name = n_label
	room.description = n_desc
	room.doors = []
	room.inbound_rooms = [ "", "", "", "", "", "", "", "", "" ]
	room.door_specs = [ "", "", "", "", "", "", "", "", "" ]
	
	print( "Creating ", room.name )
	return room
	
#} // end create()
	
static func CreateFromJSON( json_name : String )->VisualRoom:
	var new_room = VisualRoom.new()
	
	if new_room.LoadDataFromJSON( json_name ) == false:
		return null
				
	#print( "Successfully loaded json: ", json_name )
	return new_room
	
func GetDoorByChoice( choice : String ):
	for door in doors:
		if( door.choice == choice ):
			return door
	
	return null
	
func CreateDoorsFromSpecs():
	#var doors = self.doors.duplicate()
	#self.doors.clear()
	#for door in doors:
		#if door and door.get_parent() == room:
			#door.owner = null
			#self.remove_child(door)
			#door.queue_free()
	
	for door in self.doors:
		if door and door.get_parent() == self:
			door.owner = null
			self.remove_child(door)
			door.queue_free()

	self.doors.clear()
	
	var id_str = "***_***"
	var choice_str = "*"
	var dest_str = "***_***"
	
	#print("***\n")
	var hue = 0.0
	for doorspec in self.door_specs:
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
		
		var color = Color.from_hsv( hue, 0.8, 1.0 )
		hue += 1.0 / 9
		var new_door = VisualDoor.create( id_str, choice_str, dest_str, id_str, color )
		if new_door:
			self.doors.append(new_door)
			self.add_child(new_door)
			new_door.owner = get_tree().edited_scene_root
	
	var door = null
	var spec_str = ""
	for i in range(9):
		if i < self.doors.size():
			door = self.doors[i]
			if door != null:
				spec_str = "ch: " + door.choice + ", dest: " + door.destination + ";"
			else:
				spec_str = ""
		else:
			spec_str = ""
		self.door_specs[i] = spec_str
	
	self.emit_signal("property_list_changed")

func SetOwner( new_owner ):
	self.owner = new_owner
	for door in self.get_children():
		if door is VisualDoor:
			door.owner = new_owner
	
func RebuildDoors():
	self.doors.clear()
	for child in self.get_children():
		if child is VisualDoor:
			self.doors.append( child )
			
	
func ClearInboundRooms( roomlist ):
	for i in range( self.inbound_rooms.size() ):
		self.inbound_rooms[ i ] = ""
	
func RebuildInboundRooms( roomlist ):
	for door in self.doors:
	#{
		if( roomlist.has( door.destination ) ):
		#{
			var dest_room = roomlist[ door.destination ]
			
			for i in range( dest_room.inbound_rooms.size() ):
				if( dest_room.inbound_rooms[ i ] == "" ):
					dest_room.inbound_rooms[ i ] = self.id;
					break;
					
		#}  // end if rooms_dict.has...
		else:
			# Just warning when there's a door but the destination is missing.
			print( "Room: " + self.id + ", Door dest. " + door.destination + " does not exist in rooms_dict." )
		
	#} // end for door

func ReorderInboundRooms( roomlist ):
	var inbound_data = []
	inbound_data.clear()
	
	# let's populate the inbound_data array
	for inbound in self.inbound_rooms:
	#{
		if( inbound != "" and roomlist.has( inbound ) ):
			var inbound_room = roomlist[ inbound ]
			var pair = [ inbound_room.id, inbound_room.position.x ]
			inbound_data.append( pair )
			
	#}  // end for i
	
	inbound_data.sort_custom( func( a, b ): return a[ 1 ] < b[ 1 ] )

	# repopulate rooms
	for i in range( inbound_data.size() ):
		self.inbound_rooms[ i ] = inbound_data[ i ][ 0 ]
			

func ReSortDoors( roomlist ):
	var door_data = []
	door_data.clear()
	for door in self.doors:
	#{
		if( roomlist.has( door.destination ) ):
			var dest_x = roomlist[ door.destination ].position.x
			var pair = [ door, dest_x ]
			door_data.append( pair )
		else:
			door_data.append( [ door, INF ] )
			
	#} // end for door
	
	door_data.sort_custom( func( a, b ): return a[ 1 ] < b[ 1 ] )
	
	# repopulate the doors array
	self.doors.clear()
	for i in range( door_data.size() ):
		self.doors.append( door_data[ i ][ 0 ] )

	self.UpdateDoorVisuals()
	self.UpdateDoorLines()
	
func HasDestinationTo( room_id : String ) -> bool:
	for door in self.doors:
		if door.destination == room_id:
			return true
		
	return false
	
func RemoveChildren() -> void:
#{
	# Explicitly clear the doors array to ensure consistency
	if self.doors:
		self.doors.clear()
	
	# Remove and free all child nodes
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
	
#} // end RemoveChildren()

func TruncateText(text: String, max_lines: int = 5, chars_per_line: int = 40) -> String:
	var current_lines = 0
	var result = ""
	var processed_lines = 0  # Track the number of processed lines

	# Debug: Print the input text
	#print("TruncateText input for room ", name, ": '", text, "'")

	# Split the text into lines based on natural \n characters
	var lines = text.split("\n")
	#var current_text = ""

	# Process lines until we have 5 description lines
	while current_lines < max_lines and processed_lines < lines.size():
		var line = lines[processed_lines]
		# Wrap the line at 40 characters
		var wrapped_line = ""
		var words = line.split(" ")
		var current_line_chars = 0
		var current_line_text = ""

		for word in words:
			var word_length = word.length()
			if current_line_chars + word_length + (1 if current_line_text != "" else 0) > chars_per_line:
				# Start a new line
				if current_line_text != "":
					if wrapped_line != "":
						wrapped_line += "\n"
					wrapped_line += current_line_text
					current_lines += 1
					if current_lines >= max_lines:
						break
				current_line_text = word
				current_line_chars = word_length
			else:
				if current_line_text != "":
					current_line_text += " "
					current_line_chars += 1
				current_line_text += word
				current_line_chars += word_length

		# Add the last line if it fits
		if current_line_text != "" and current_lines < max_lines:
			if wrapped_line != "":
				wrapped_line += "\n"
			wrapped_line += current_line_text
			current_lines += 1

		# Add the wrapped line to the result
		if wrapped_line != "":
			if result != "":
				result += "\n"
			result += wrapped_line

		processed_lines += 1  # Update the number of processed lines

	# If we haven't reached 5 lines, process more text
	if current_lines < max_lines:
		# Join the remaining lines into a single string
		var remaining_text = ""
		for i in range(processed_lines, lines.size()):
			if remaining_text != "":
				remaining_text += " "
			remaining_text += lines[i]

		# Split the remaining text into words and continue wrapping
		var words = remaining_text.split(" ")
		var current_line_chars = 0
		var current_line_text = ""

		for word in words:
			var word_length = word.length()
			if current_line_chars + word_length + (1 if current_line_text != "" else 0) > chars_per_line:
				# Start a new line
				if current_line_text != "":
					if result != "":
						result += "\n"
					result += current_line_text
					current_lines += 1
					if current_lines >= max_lines:
						break
				current_line_text = word
				current_line_chars = word_length
			else:
				if current_line_text != "":
					current_line_text += " "
					current_line_chars += 1
				current_line_text += word
				current_line_chars += word_length

		# Add the last line if it fits
		if current_line_text != "" and current_lines < max_lines:
			if result != "":
				result += "\n"
			result += current_line_text
			current_lines += 1

	# If we still haven't reached 5 lines, add empty lines
	while current_lines < max_lines:
		if result != "":
			result += "\n"
		result += ""
		current_lines += 1

	# If there are more lines to process, append the ellipsis
	if processed_lines < lines.size():
		if result != "":
			result += "\n..."
		else:
			result = "..."

	# Debug: Print the result
	#print("TruncateText result for room ", name, ": '", result, "'")
	return result
		
func SetupVisuals():
#{
	#if not Engine.is_editor_hint():
	#	return  # Safeguard: Only run in the editor

	if not has_node("Panel"):
		# Create a Panel as the visual base with a border
		var panel = Panel.new()
		panel.name = "Panel"

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
		vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		# Set a fixed width to ensure the text wraps at 40 characters
		panel.add_child(vbox)

		# Add a Label for the title (room name)
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = name  # Use the node's name (e.g., "rm000-Welcome")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(name_label)

		var separator = HSeparator.new()
		separator.name = "Separator"
		separator.custom_minimum_size.y = 2  # Match the 2-pixel border thickness
		var separator_style = StyleBoxFlat.new()
		separator_style.border_color = Color(0.8, 0.8, 0.8, 1.0)  # Match the panel's border color
		separator_style.border_width_top = 2  # Match the thickness
		separator.add_theme_stylebox_override("separator", separator_style)
		vbox.add_child(separator)
		
		# Add a Label for the truncated description
		var desc_label = Label.new()
		desc_label.name = "DescLabel"
		desc_label.text = TruncateText(description, 5, 40)  # Truncate to 5 lines, 40 chars
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Enable word wrapping
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		desc_label.max_lines_visible = 6  # Limit to 6 lines (5 description + ellipsis)
		vbox.add_child(desc_label)

		# Defer resizing the panel until the labels are fully laid out
		#call_deferred("resize_panel", panel, vbox, name_label, desc_label)
		resize_panel(panel, vbox, name_label, desc_label)
	
		# Calculate the horizontal center of the Panel
		var panel_center_x = -panel.size.x / 2

		# Calculate the vertical position of the Separator
		var name_label_height = name_label.get_minimum_size().y
		var separation = vbox.get_theme_constant("separation")
		var separator_y = name_label_height + separation  # Separator's top edge relative to VBox

		# Adjust for VBox's position within the Panel
		separator_y += vbox.position.y

		# Set the Panel's position to align the Room's origin with the center and separator
		panel.position = Vector2(panel_center_x, -separator_y)
		
	else:
		print("Panel already exists for room: ", name)
	
#} // end SetupVisuals()

func resize_panel(panel: Panel, vbox: VBoxContainer, name_label: Label, desc_label: Label):

	# Ensure the labels have updated their sizes
	name_label.queue_redraw()
	desc_label.queue_redraw()

	# Get the font and default font size
	#var font = desc_label.get_theme_font("font") if desc_label.has_theme_font("font") else desc_label.get_theme_default_font()
	var font_size = 32
	var line_spacing = desc_label.get_theme_constant("line_spacing") if desc_label.has_theme_constant("line_spacing") else 0

	# Load the monospace font
	var monospace_font = FontFile.new()
	monospace_font.font_data = load("res://Fonts/Mx437_IBM_XGA_AI_7x15_Regular.ttf")
	name_label.add_theme_font_override("font", monospace_font)
	desc_label.add_theme_font_override("font", monospace_font)
	name_label.add_theme_font_size_override("font_size", font_size)
	desc_label.add_theme_font_size_override("font_size", font_size)

	# Calculate the width of 40 characters
	var test_string = "M".repeat(40)
	var text_width = monospace_font.get_string_size(test_string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	# Define padding and border
	var padding = Vector2(20, 20)
	var border_width = 4

	# Set label sizes
	name_label.custom_minimum_size.x = text_width
	name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	desc_label.custom_minimum_size.x = text_width
	desc_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	# Set VBoxContainer size
	vbox.custom_minimum_size.x = text_width
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Calculate total panel size
	var line_height = monospace_font.get_height(font_size) + line_spacing
	var desc_height = line_height * 6
	var name_size = name_label.get_minimum_size()
	var total_width = text_width + padding.x + border_width
	var separator_size = vbox.get_node("Separator").get_minimum_size()
	var total_height = name_size.y + separator_size.y + desc_height + vbox.get_theme_constant("separation") * 2 + padding.y + border_width

	# Set panel size
	panel.custom_minimum_size = Vector2(total_width, total_height)
	panel.size = Vector2(total_width, total_height)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Center the VBoxContainer within the Panel
	var vbox_x_offset = (total_width - text_width) / 2  # Should be (584 - 560) / 2 = 12
	vbox.position = Vector2(vbox_x_offset + 1, padding.y / 2)

func UpdateDoorVisuals():
	# Clear the door_visuals array
	door_visuals.clear()
	
	# Check for an existing HBoxContainer
	var hbox = get_node_or_null("DoorVisualsContainer")
	if hbox:
		# Remove existing door visual children from the HBoxContainer
		for child in hbox.get_children():
			hbox.remove_child(child)
			child.queue_free()
		
		# Remove the HBoxContainer if there are no doors
		if doors.is_empty():
			hbox.get_parent().remove_child(hbox)
			hbox.queue_free()
			hbox = null
			#print("Removed DoorVisualsContainer due to no doors in room: ", name)
	
	# Create a new HBoxContainer if needed (either no HBoxContainer or it was removed)
	if not hbox and not doors.is_empty():
		hbox = HBoxContainer.new()
		hbox.name = "DoorVisualsContainer"
		# Get the Panel's width for the HBoxContainer
		var panel = get_node_or_null("Panel")
		var panel_width = panel.size.x if panel else 584 # Fallback to default Panel width
		panel_width += 100  # increase so the lock icon moves to the side
		hbox.custom_minimum_size = Vector2(panel_width, 20) # Match Panel width, match ColorRect height
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Set the separation to spread the ColorRect nodes across the Panel's width with margins
		var margin = 80 # Pixels on each side
		var total_width = panel_width - 2 * margin # Available width after margins
		var node_width = doors.size() * 20 # Total width of ColorRect nodes
		var gaps = doors.size() - 1 # Number of gaps between nodes
		var separation = (total_width - node_width) / gaps if gaps > 0 else 0
		hbox.add_theme_constant_override("separation", separation)		
		
		add_child(hbox)
		hbox.owner = get_tree().edited_scene_root
		# Lock the HBoxContainer in the editor
		hbox.set_meta("_edit_lock_", true)
		# Set z-index to render in front of the Panel
		hbox.z_index = 1
		# Position the HBoxContainer so the middle of the ColorRect aligns with the Panel's bottom
		if panel:
			var separator_y = panel.position.y  # This is -separator_y from SetupVisuals()
			hbox.position = Vector2(-panel_width / 2, panel.size.y + separator_y - 10) # Align ColorRect center with Panel bottom
		else:
			hbox.position = Vector2(-panel_width / 2, 0)
		# Debug positioning
		#print("Created new DoorVisualsContainer for room: ", name)
		#print("  HBoxContainer position: ", hbox.position, ", size: ", hbox.size)
	
	# Create new door visuals if there are doors
	if hbox:
		for door in doors:
			var door_visual = ColorRect.new()
			door_visual.name = "DoorVisual_" + door.name
			door_visual.size = Vector2(20, 20)
			door_visual.custom_minimum_size = Vector2(20, 20) # Ensure minimum size
			door_visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			door_visual.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			door_visual.color = door.color #Color(1, 0, 0) # Red for visibility
			door_visual.visible = true
			hbox.add_child(door_visual)
			door_visual.owner = get_tree().edited_scene_root
			door_visual.queue_redraw() # Force redraw
			door_visuals.append(door_visual)
			# Debug door visual
			#print("  Added door visual for door: ", door.name, " in room: ", name)
			#print("    DoorVisual position: ", door_visual.position, ", size: ", door_visual.size)
		# Force the HBoxContainer to update its layout
		hbox.queue_redraw()

func UpdateInboundVisuals():
#{
	# Clear the inbound_visuals array
	inbound_visuals.clear()
	
	# check to see if the array is empty
	var inbound_is_empty = true;
	var inbound_count = 0;
	for i in range( 9 ):
	#{
		if( inbound_rooms[ i ] != "" ):
			inbound_count += 1
	#}		
	if( inbound_count > 0 ):
		inbound_is_empty = false;

	# Check for an existing HBoxContainer
	var hbox = get_node_or_null("InboundVisualsContainer")
	if( hbox ):
	#{
		# Remove existing door visual children from the HBoxContainer
		for child in hbox.get_children():
			hbox.remove_child(child)
			child.queue_free()
					
		# Remove the HBoxContainer if there are no doors
		if( inbound_is_empty ):
		#{
			hbox.get_parent().remove_child(hbox)
			hbox.queue_free()
			hbox = null
			#print("Removed InboundVisualsContainer due to no inbound links in room: ", name)
		
		#}  // end if inbound_is_empty
		
	#}  // end if hbox
	
	# Create a new HBoxContainer if needed (either no HBoxContainer or it was removed)
	if not hbox and not inbound_is_empty:
	#{
		hbox = HBoxContainer.new()
		hbox.name = "InboundVisualsContainer"
		# Get the Panel's width for the HBoxContainer
		var panel = get_node_or_null("Panel")
		var panel_width = panel.size.x if panel else 584 # Fallback to default Panel width
		panel_width += 100  # increase so the lock icon moves to the side
		hbox.custom_minimum_size = Vector2(panel_width, 20) # Match Panel width, match ColorRect height
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Set the separation to spread the ColorRect nodes across the Panel's width with margins
		var margin = 80 # Pixels on each side
		var total_width = panel_width - 2 * margin # Available width after margins
		var node_width = inbound_count * 20 # var node_width = doors.size() * 20 # Total width of ColorRect nodes
		var gaps = inbound_count - 1 # var gaps = doors.size() - 1 # Number of gaps between nodes
		var separation = (total_width - node_width) / gaps if gaps > 0 else 0
		hbox.add_theme_constant_override("separation", separation)		
		
		add_child(hbox)
		hbox.owner = get_tree().edited_scene_root
		# Lock the HBoxContainer in the editor
		hbox.set_meta("_edit_lock_", true)
		# Set z-index to render in front of the Panel
		hbox.z_index = 1
		# Position the HBoxContainer so the middle of the ColorRect aligns with the Panel's bottom
		if panel:
			var separator_y = panel.position.y  # This is -separator_y from SetupVisuals()
			hbox.position = Vector2(-panel_width / 2, separator_y - 20) # Align ColorRect center with Panel bottom
		else:
			hbox.position = Vector2(-panel_width / 2, 0)
		
		# Debug positioning
		#print("Created new InboundVisualsContainer for room: ", name)
		#print("  HBoxContainer position: ", hbox.position, ", size: ", hbox.size)
		
	#}  // end if not hbox
	
	# Create new inbound visuals if there are inbound links
	if( hbox ):
		for inbound in inbound_rooms:
			if( inbound == "" ):
				continue
			
			var color = Color.GRAY
			
			var inbound_room = null
			
			if( !editor_map ):
				print("Error: editor_map is null in UpdateInboundVisuals")
				
			if( editor_map.rooms_dict.has( inbound ) ):
			#{
				#print( "Rooms dictionary has " + inbound )
				inbound_room = editor_map.rooms_dict[ inbound ]
				for inbound_door in inbound_room.doors:
				#{
					if( inbound_door.destination == id ):
						#print( "inbound door found" )
						color = inbound_door.color
						#print( color )
				#}
			#}
			
			var inbound_visual = ColorRect.new()
			inbound_visual.name = "InboundVisual_" + inbound
			inbound_visual.size = Vector2( 20, 20 )
			inbound_visual.custom_minimum_size = Vector2( 20, 20 ) # Ensure minimum size
			inbound_visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			inbound_visual.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			#print( "Setting inbound visual to : ", color )
			inbound_visual.color = color #Color(1, 0, 0) # Red for visibility
			inbound_visual.visible = true
			hbox.add_child( inbound_visual )
			inbound_visual.owner = get_tree().edited_scene_root
			inbound_visual.queue_redraw() # Force redraw
			inbound_visuals.append( inbound_visual )
			# Debug inbound visual
			#print("  Added inbound visual for inbound room: ", inbound, " in room: ", name)
			#print("    DoorVisual position: ", inbound_visual.position, ", size: ", inbound_visual.size)
		# Force the HBoxContainer to update its layout
		hbox.queue_redraw()
		
#}  // end func UpdateInboundVisuals()

func UpdateDoorLines():
	#print("UpdateDoorLines called for room: ", name, " with doors.size(): ", doors.size(), ", door_visuals.size(): ", door_visuals.size(), ", is_inside_tree(): ", is_inside_tree())
	
	#if not Engine.is_editor_hint() or not is_inside_tree():
		#print("Skipping UpdateDoorLines for room: ", name, " during cleanup or non-editor context")
	#	return

# Clear the door_visuals array
	door_lines.clear()
	
	# Step 1: Delete existing LinesContainer if it exists
	var lines_container = get_node_or_null("LinesContainer")
	if lines_container:
		# Remove existing door visual children from the HBoxContainer
		for child in lines_container.get_children():
			lines_container.remove_child(child)
			child.queue_free()
			
		remove_child(lines_container)
		lines_container.queue_free()
	
	if doors.is_empty():
		#print( "No doors in room: ", self.id )
		return
	
	var y_offset = 100
	
	# Step 2: Create a new LinesContainer as a Node2D
	lines_container = Node2D.new()
	lines_container.name = "LinesContainer"
	lines_container.position = Vector2(0, -y_offset )  
	add_child(lines_container)
	lines_container.owner = get_tree().edited_scene_root
	# Lock only the container in the editor
	lines_container.set_meta("_edit_lock_", true)
	
	# Clear the door_lines array
	door_lines.clear()

	# Check for DoorVisualsContainer
	var hbox = get_node_or_null("DoorVisualsContainer")
	if not hbox:
		print("DoorVisualsContainer not found for room: ", name)
		return
	hbox.queue_redraw()
	
	# Ensure doors and door_visuals are aligned
	if doors.size() != door_visuals.size():
		print("Mismatch between doors and door_visuals for room: ", name, " (doors: ", doors.size(), ", visuals: ", door_visuals.size(), ")")
		return

	if door_visuals.is_empty():
		print("No door visuals available for room: ", name)
		return

	var panel = get_node_or_null("Panel")
	if not panel:
		print("Panel not found for room: ", name)
		return
	var start_pos = Vector2(0, panel.position.y + panel.size.y + 10)

	# Iterate over doors and door visuals
	for i in range(doors.size()):
		var door = doors[i]
		var panel_width = panel.size.x
		panel_width += 100  # increase so the lock icon moves to the side
		var margin = 80
		var total_width = panel_width - 2 * margin
		var node_width = doors.size() * 20
		var gaps = doors.size() - 1
		var separation = (total_width - node_width) / gaps if gaps > 0 else 0
		var total_content_width = node_width + separation * gaps
		var start_x = -total_content_width / 2  # Center the content
		var visual_x = start_x + i * (20 + separation) + 10  # i is the index, +10 to center on ColorRect
		var adjusted_start_pos = start_pos
		adjusted_start_pos.x = visual_x
		adjusted_start_pos.y += y_offset
		
		if not editor_map or not editor_map.rooms_dict.has(door.destination):
			#print("Skipping line for door ", door.name, ": destination ", door.destination, " not found")
			continue

		var dest_room = editor_map.rooms_dict[door.destination]
		if not dest_room:
			#print("Skipping line for door ", door.name, ": destination room is null")
			continue

		# Find the matching InboundVisual
		var inbound_visual = null
		var inbound_index = dest_room.inbound_rooms.find(self.id)
		if inbound_index != -1 and inbound_index < dest_room.inbound_visuals.size():
			inbound_visual = dest_room.inbound_visuals[inbound_index]
	
		if not inbound_visual:
			#print("Skipping line for door ", door.name, ": no matching InboundVisual found in ", dest_room.name)
			continue

		var inbox = dest_room.get_node_or_null("InboundVisualsContainer")
		if not inbox:
			print("InboundVisualsContainer not found for room: ", dest_room.name)
			continue

		var dest_panel = dest_room.get_node_or_null("Panel")
		if not dest_panel:
			print("Panel not found for destination room: ", dest_room.name)
			continue
		var end_pos = Vector2(0, dest_panel.position.y - 20)  # Top center of dest panel in dest_room space
		var inbound_count = 0
		for room_id in dest_room.inbound_rooms:
			if room_id != "":
				inbound_count += 1
		node_width = inbound_count * 20
		gaps = inbound_count - 1
		separation = (total_width - node_width) / gaps if gaps > 0 else 0
		total_content_width = node_width + separation * gaps
		start_x = -total_content_width / 2
		visual_x = start_x + inbound_index * (20 + separation) + 10
		end_pos.x = visual_x
		end_pos.y += y_offset
		
		# Transform end_pos to current Room's local space
		end_pos += dest_room.position - self.position
		
		var line = CustomLine2D.new()
		line.set_line(adjusted_start_pos, end_pos, door.color, 5.0)

		# Lock the CustomLine2D node to prevent viewport movement
		line.set_meta("_edit_lock_", true)

		# Add the line to the LinesContainer instead of the Room
		lines_container.add_child(line)
		door_lines.append(line)
		line.owner = get_tree().edited_scene_root
		#print("Drew line for door ", door.name, " from ", adjusted_start_pos, " to ", end_pos)
