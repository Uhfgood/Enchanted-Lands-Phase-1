@tool
class_name Room extends Node2D

# Reference to the editor_map node (set by editor_map.gd)
var editor_map: Node = null

@export var room_id : String = "rmXXX"
@export var room_parent : String = "lvXXXrmXX"
@export var room_name : String = "blank_room"
@export_multiline var description : String = "Modify the description text to describe your scene, and add your choices.  Make sure to number your choices up to 9, and add 0 for Exit."

var doors : Array = []

# Convert snake_case to PascalCase (e.g., "hotel_max_stash" -> "HotelMaxStash")
func ToPascalCase( snake: String ) -> String:
	var words = snake.split("-")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word.capitalize()
	return result

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
	self.room_id = json_data[ "id" ]
	self.room_parent = json_data[ "parent" ]
	self.room_name = json_data[ "name" ]
	self.name = self.room_id + "-" + ToPascalCase( self.room_name )
	self.description = json_data[ "description" ]
	print( "Creating " + self.name + " from JSON data." )
	
	# create and attach door nodes
	if "doors" in json_data:
		for door_data in json_data[ "doors" ]:
			var door_id = door_data[ "id" ]
			var choice = door_data[ "choice" ] 
			var dest = door_data[ "destination" ]
			var dest_substr = dest.substr( 10, dest.length() - 21 )
			var door_name = "DoorTo" + ToPascalCase( dest_substr )
			print( "Creating " + door_name + " from JSON data." )
			var new_door = Door.create( door_id, choice, dest, door_name )
			if new_door:
				doors.append( new_door )
				add_child( new_door )
				print( "Successfully created " + new_door.name + "." )
			else:
				print( "New door not valid." )
			
	return true
	
static func CreateFromJSON( json_name : String )->Room:
	var new_room = Room.new()
	
	if new_room.LoadDataFromJSON( json_name ) == false:
		return null
				
	print( "Successfully loaded json: ", json_name )
	return new_room
	
func GetDoorByChoice( choice : String ):
	for door in doors:
		if( door.choice == choice ):
			return door
	
	return null
	

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
	if not Engine.is_editor_hint():
		return  # Safeguard: Only run in the editor

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
