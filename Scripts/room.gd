@tool
class_name Room extends Node2D

# Reference to the editor_map node (set by editor_map.gd)
var editor_map: Node = null

@export var id : String = "rmXXX"

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
	
# Truncate a string to a max length, adding "..." if truncated
#func TruncateText(text: String, max_length: int) -> String:
#	if text.length() <= max_length:
#		return text
#	return text.substr(0, max_length) + "..."	

func TruncateText(text: String, max_lines: int = 5, chars_per_line: int = 40) -> String:
	var current_lines = 0
	var result = ""
	var processed_lines = 0  # Track the number of processed lines

	# Debug: Print the input text
	#print("TruncateText input for room ", name, ": '", text, "'")

	# Split the text into lines based on natural \n characters
	var lines = text.split("\n")
	var current_text = ""

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
	print( "Creating Room from JSON Data" )
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
	
func SetupVisuals(room):
	if not Engine.is_editor_hint():
		return  # Safeguard: Only run in the editor

	if room != self:
		return # Ignore signals for other rooms

	print("Running SetupVisuals for room: ", name)

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
	else:
		print("Panel already exists for room: ", name)

func resize_panel(panel: Panel, vbox: VBoxContainer, name_label: Label, desc_label: Label):
	
	# Debug: Confirm the function is being called
	print("resize_panel called for room: ", name)
	
	# Ensure the labels have updated their sizes
	name_label.queue_redraw()
	desc_label.queue_redraw()

	# Get the font and default font size
	var font = desc_label.get_theme_font("font") if desc_label.has_theme_font("font") else desc_label.get_theme_default_font()
	var font_size = desc_label.get_theme_font_size("font_size") if desc_label.has_theme_font_size("font_size") else 16
	var line_spacing = desc_label.get_theme_constant("line_spacing") if desc_label.has_theme_constant("line_spacing") else 0

	# Calculate the width of 40 characters with the default font size
	var test_string = "M".repeat(40)  # Use "M" for a conservative average width
	var text_width = font.get_string_size(test_string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	# Define padding for the panel
	var padding = Vector2(20, 20)  # 10 pixels on each side

	# Set the NameLabel's max width to the calculated text width
	name_label.custom_minimum_size.x = text_width
	name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_label.size = Vector2(text_width, name_label.get_minimum_size().y)

	# Set the DescLabel's max width to the calculated text width to ensure wrapping
	desc_label.custom_minimum_size.x = text_width
	desc_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	desc_label.size = Vector2(text_width, desc_label.get_minimum_size().y)
	# Debug: Print the font size
	print("DescLabel font size for room ", name, ": ", desc_label.get_theme_font_size("font_size"))

	# Set the VBoxContainer's width to the same value
	vbox.custom_minimum_size.x = text_width
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size = Vector2(text_width, vbox.get_minimum_size().y)

	# Define the maximum number of description lines
	var max_lines = 5  # Maximum description lines (excluding ellipsis)

	# Since TruncateText now handles wrapping, we don't need to estimate lines
	var wrapped_lines = desc_label.text.split("\n").size()
	if wrapped_lines > max_lines + 1:  # +1 for the ellipsis line
		wrapped_lines = max_lines + 1

	# Calculate the height of 6 lines (5 description lines + ellipsis)
	var line_height = font.get_height(font_size) + line_spacing
	var desc_height = line_height * 6  # 6 lines total

	# Get the size of the NameLabel
	var name_size = name_label.get_minimum_size()

	# Calculate the total size needed
	var total_width = text_width  # Use text_width directly
	var total_height = name_size.y + desc_height + vbox.get_theme_constant("separation")

	# Add padding for the panel's border and some extra space
	var border_width = 4  # 2 pixels on each side (left + right, top + bottom)
	total_width += padding.x + border_width
	total_height += padding.y + border_width

	# Debug: Print the calculated widths
	print("Font size:", font_size)
	print("Calculated text width for 40 chars:", text_width)
	print("Total panel width:", total_width)

	# Set the panel's custom_minimum_size and size
	panel.custom_minimum_size = Vector2(total_width, total_height)
	panel.size = Vector2(total_width, total_height)

	# Ensure the panel shrinks to its minimum size
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
