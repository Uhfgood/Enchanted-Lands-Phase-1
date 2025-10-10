@tool
class_name LayoutRoom extends Node2D

# Reference to the layout_tool node (set by layout_tool.gd)
var layout_tool: Node = null

signal clicked( room );

var roomdata : Room

func update_name_label(retry_count: int = 0, max_retries: int = 5) -> void:
	if not is_inside_tree():  # Safety check: ensure node is in the scene tree
		return
	var name_label = get_node_or_null("Panel/VBox/NameLabel")
	if name_label:
		name_label.text = self.roomdata.label
		name_label.queue_redraw()
	elif retry_count < max_retries:
		call_deferred("update_name_label", retry_count + 1, max_retries)  # Retry without timer
	else:
		print("Max retries reached, NameLabel still not found for room: ", name)
			

# Update the DescLabel text
func update_description_label() -> void:

	var desc_label = get_node_or_null("Panel/VBox/DescLabel")
	if desc_label:
		desc_label.text = TruncateText( self.roomdata.description, 5, 40 )
		desc_label.queue_redraw()  # Ensure the label redraws

@export var inbound_rooms : Array = [ "", "", "", "", "", "", "", "", "" ]
@export var door_specs : Array = [ "", "", "", "", "", "", "", "", "" ] : set = _set_door_specs
func _set_door_specs( doorspecs : Array ):
	door_specs = doorspecs
	
var layout_doors = {}
func GetDoorData() -> Array:
	var door_data = []
	for door in self.roomdata.doors:
		if door is Door and self.roomdata != null:
			door_data.append({
				"id": door.id,
				"choice": door.choice,
				"destination": door.destination
			})
	return door_data

var original_id : String = "XXX"

var previous_position : Vector2 = Vector2()

func _get_property_list() -> Array[ Dictionary ]:
#{
	var properties: Array[ Dictionary ] = []
	properties.append(
		{
			"name": "id",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		}
	)
	properties.append(
		{
			"name": "label",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		}
	)
	properties.append(
		{
			"name": "description",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT,
			"hint_string": ""
		}
	)
	
	return properties

#}  // end func _get_property list()

func _get( property: StringName ) -> Variant:
#{	
	if( self.roomdata != null ):
	#{
		if( property == "id" ):
			return self.roomdata.id
			
		if( property == "label" ):
			return self.roomdata.label
	
		if( property == "description" ):
			return self.roomdata.description
						
	#}  // end if self.roomdata != null
	
	return null
#}

func _set( property: StringName, value: Variant ) -> bool:
#{
	if( self.roomdata != null ):
	#{
		if( property == "id" ):
		#{
			self.roomdata.id = value
			var tokens = value.split("_")
			var new_label = ""
			var size = tokens.size()
			for i in range(1, size):
				if i < size - 1:
					new_label += tokens[i] + " "
				else:
					new_label += tokens[i]
			
			self.roomdata.label = new_label
			self.name = new_label
			
			if has_node("Panel"):
				update_name_label()
			else:
				call_deferred("update_name_label", 0, 5)
		
		#}  // id
		
		if property == "label":
		#{
			self.name = value
			self.roomdata.label = value
			if has_node("Panel"):
				update_name_label()
			else:
				call_deferred("update_name_label", 0, 5)
			print( "Updated label to: ", roomdata.label )
			return true
		
		#}  // label
		
		if property == "description":
		#{
			self.roomdata.description = value
			update_description_label()
			print( "Updated description to: ", roomdata.description )
			return true
		
		#}  // description
		
	#}  // if self.roomdata != null
	
	return false
#}

static func Create( n_id : String, n_label : String, n_desc : String ) -> LayoutRoom:
#{
	var room = LayoutRoom.new();
	if( !room ):
		return null;
	
	room.roomdata = Room.Create( n_id, n_label, n_desc );
	room.original_id = n_id;
	room.name = n_label;
	room.inbound_rooms = [ "", "", "", "", "", "", "", "", "" ];
	room.door_specs = [ "", "", "", "", "", "", "", "", "" ];
	room.SetupVisuals();
	print( "Creating ", room.name );
	return room;
	
#} // end create()
	
static func CreateFromJSON( json_name : String )->LayoutRoom:
#{
	var hue = 0.0
	var new_room = LayoutRoom.new()
		
	new_room.roomdata = Room.CreateFromJSON( json_name )
	if( new_room.roomdata ):
	#{
		var i = 0
		new_room.name = new_room.roomdata.label
		
		for door in new_room.roomdata.doors:
		#{
			var color = Color.from_hsv( hue, 0.8, 1.0 )
			hue += 1.0 / 9
			var door_name = "Door_To_" + door.destination.substr( 4 )
			var new_door = LayoutDoor.create( door_name, color )
			if new_door:
			#{
				new_room.layout_doors[ door.id ] = new_door
				new_room.add_child( new_door )
			
			#}  # end if new_door
		
			if( i < 9 ):
				var spec_str = "ch: " + door.choice + ", dest: " + door.destination + ";"
				new_room.door_specs[ i ] = spec_str
				i += 1
		
		#}  # end for door

		new_room.SetupVisuals()
	
	#}  # end if new_room.roomdata
	else:
		print( "Failed to load room: ", json_name )
		return null
		
	#}  // end if new_room
	
	return new_room

#}  // end CreateFromJSON()

func CreateDoorsFromSpecs():
	
	for edoor in self.layout_doors.values():
		if edoor:
			edoor.owner = null
			self.remove_child(edoor)
			edoor.queue_free()
	self.layout_doors.clear()
	
	if( self.roomdata ):
		self.roomdata.doors.clear()
		
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

		if( roomdata ):
			var room_door = Door.create( id_str, choice_str, dest_str )
			if room_door:
				self.roomdata.doors.append( room_door )
		
		var color = Color.from_hsv( hue, 0.8, 1.0 )
		hue += 1.0 / 9
		var new_door = LayoutDoor.create( id_str, color )
		if new_door:
			self.layout_doors[ id_str ] = new_door
			self.add_child( new_door )
			
			if( get_tree() ):
				var root = get_tree().edited_scene_root
				if( root ):
					new_door.owner = root
				else:
					print( "LayoutRoom: Skipped door owner set due to null scene root" )
			else:
				print( "get_tree() returned null, skipping door owner set")
					
	var door = null
	var spec_str = ""
	for i in range(9):
		if i < self.roomdata.doors.size():
			door = self.roomdata.doors[ i ]
			if door != null:
				spec_str = "ch: " + door.choice + ", dest: " + door.destination + ";"
			else:
				spec_str = ""
		else:
			spec_str = ""
			
		self.door_specs[ i ] = spec_str
	
	self.emit_signal("property_list_changed")

func SetOwner( new_owner ):
	self.owner = new_owner
	for door in self.get_children():
		if door is LayoutDoor:
			door.owner = new_owner
	
func RebuildDoors():
	self.layout_doors.clear()
	for child in self.get_children():
		if child is LayoutDoor:
			self.layout_doors.append( child )
			
	
func ClearInboundRooms():
	for i in range( self.inbound_rooms.size() ):
		self.inbound_rooms[ i ] = ""
	
func RebuildInboundRooms( roomlist ):
	for door in self.roomdata.doors:
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
	for door in self.roomdata.doors:
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
	self.roomdata.doors.clear()
	for i in range( door_data.size() ):
		self.roomdata.doors.append( door_data[ i ][ 0 ] )
	
func HasDestinationTo( room_id : String ) -> bool:
	for door in self.roomdata.doors:
		if door.destination == room_id:
			return true
		
	return false
	
func RemoveChildren() -> void:
#{
	# Explicitly clear the doors array to ensure consistency
	self.roomdata.doors.clear()	
	self.layout_doors.clear()
	
	# Remove and free all child nodes
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
	
#} // end RemoveChildren()

func TruncateText(text: String, max_lines: int = 5, chars_per_line: int = 40) -> String:
	var current_lines = 0
	var result = ""
	var processed_lines = 0  # Track the number of processed lines

	# Split the text into lines based on natural \n characters
	var lines = text.split("\n")

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

	return result
		
func _create_click_area(panel: Panel) -> void:
	if has_node("ClickArea"):
		get_node("ClickArea").queue_free()

	var area = Area2D.new()
	area.name = "ClickArea"
	add_child(area)

	# Position at the panel center
	area.position = panel.position + panel.size * 0.5

	var shape_node = CollisionShape2D.new()
	shape_node.name = "ClickShape"
	var rect_shape = RectangleShape2D.new()
	rect_shape.extents = panel.size * 0.5
	shape_node.shape = rect_shape
	shape_node.disabled = false
	area.add_child(shape_node)

	# Connect signals
	area.connect("input_event", Callable(self, "_on_area_input"))
	area.connect("mouse_entered", Callable(self, "_on_area_hover_entered"))
	area.connect("mouse_exited", Callable(self, "_on_area_hover_exited"))

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var shift = Input.is_key_pressed(KEY_SHIFT)
		var ctrl = Input.is_key_pressed(KEY_CTRL)
		print("Room clicked: ", name, ", Shift: ", shift, ", Ctrl: ", ctrl)
		emit_signal("clicked", self, shift, ctrl)

func _on_area_hover_entered():
	#print("Mouse entered!")
	mouse_inside = true;
	pass

func _on_area_hover_exited():
	#print("Mouse exited!")
	mouse_inside = false;
	pass
	
func _update_click_area() -> void:
#{
	var panel = get_node_or_null("Panel")
	var area = get_node_or_null("ClickArea")
	var shape_node = area and area.get_node_or_null("ClickShape")
	if not panel or not area or not shape_node:
		return

	area.position = panel.position + panel.size * 0.5

	if shape_node.shape is RectangleShape2D:
		shape_node.shape.extents = panel.size * 0.5
	else:
		var rect_shape = RectangleShape2D.new()
		rect_shape.extents = panel.size * 0.5
		shape_node.shape = rect_shape

#}  // end _update_click_area()

func SetupVisuals():
#{
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

		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
		name_label.text = self.roomdata.label  # Use the node's name (e.g., "rm000-Welcome")
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
		desc_label.text = TruncateText( self.roomdata.description, 5, 40 )  # Truncate to 5 lines, 40 chars
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Enable word wrapping
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		desc_label.max_lines_visible = 6  # Limit to 6 lines (5 description + ellipsis)
		vbox.add_child(desc_label)

		resize_panel(panel, vbox, name_label, desc_label)
	
		## Calculate the horizontal center of the Panel
		#var panel_center_x = -panel.size.x / 2
#
		## Calculate the vertical position of the Separator
		#var name_label_height = name_label.get_minimum_size().y
		#var separation = vbox.get_theme_constant("separation")
		#var separator_y = name_label_height + separation  # Separator's top edge relative to VBox
#
		## Adjust for VBox's position within the Panel
		#separator_y += vbox.position.y
#
		## Set the Panel's position to align the Room's origin with the center
		#panel.position = Vector2(panel_center_x, -separator_y)
		panel.position = -( panel.size / 2 );
		
		_create_click_area( panel );
		
		
	else:
		print("Panel already exists for room: ", name)
	
#} // end SetupVisuals()

var is_selected = true;

# Call this whenever selection changes
func UpdateHighlight():
#{
	var panel = get_node_or_null( "Panel" );
	if panel:
		var style = panel.get_theme_stylebox( "panel" );
		if not style:
			style = StyleBoxFlat.new();
		if is_selected:
			style.border_color = Color( 1, 0.5, 0, 1 );  # Orange highlight
			style.border_width_left = 3;
			style.border_width_right = 3;
			style.border_width_top = 3;
			style.border_width_bottom = 3;
		else:
			style.border_color = Color( 0.8, 0.8, 0.8, 1 );  # Normal
			style.border_width_left = 2;
			style.border_width_right = 2 ;
			style.border_width_top = 2;
			style.border_width_bottom = 2;
		panel.add_theme_stylebox_override( "panel", style );

#}  // end UpdateHighlight()

func resize_panel(panel: Panel, vbox: VBoxContainer, name_label: Label, desc_label: Label):
#{
	# Ensure the labels have updated their sizes
	name_label.queue_redraw()
	desc_label.queue_redraw()

	# Get the font and default font size
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
	
#}  // end resize_panel()

var was_clicked: bool = false;
var mouse_inside : bool = false;

# calculate the actual center of the panel
#func GetCenterPos() -> Vector2:
##{
	#var center_pos = Vector2.ZERO;
	#var panel = self.get_node_or_null( "Panel" );
	#var vbox = panel.get_node_or_null( "VBox" );
	#var name_label = vbox.get_node_or_null( "NameLabel" );
#
	#var separator_y = 0;
	#var center_y = 0;
#
	#if( name_label and vbox and panel ):
	##{
		## Calculate the vertical position of the Separator
		#var name_label_height = name_label.get_minimum_size().y;
		#var separation = vbox.get_theme_constant("separation");
		#separator_y = name_label_height + separation;  # Separator's top edge relative to VBox
			#
		## Adjust for VBox's position within the Panel
		#separator_y += vbox.position.y;
		#center_y = panel.size.y / 2;
	##}
#
	#center_pos = Vector2( position.x, ( position.y - separator_y ) + center_y );
#
	#return( center_pos );
	
#}  // end func GetCenterPos()

func GetPanelRect() -> Rect2:
#{
	var panel = get_node_or_null( "Panel" );
	if( not panel ):
		return( Rect2( Vector2.ZERO, Vector2.ZERO ) );

	var top_left = panel.global_position - ( panel.size / 2 );

	print("Top-left:", top_left, "Size:", panel.size)

	return( Rect2( top_left, panel.size ) );
	
#}  // end GetPanelRect

# For easy hit testing later.
func GetPanelRect_old() -> Rect2:
#{
	var panel = get_node_or_null( "Panel" );
	if( not panel ):
		return( Rect2( Vector2.ZERO, Vector2.ZERO ) );

	# Center position of the panel in world coordinates
	#var center = GetCenterPos();
	
	# Top-left corner
	#var top_left = center - panel.size / 2;
	var top_left = panel.global_position - ( panel.size / 2 );

	#var rect_top_left = panel.global_position
	#var rect_size = panel.size
	print("Top-left:", top_left, "Size:", panel.size)

	return( Rect2( top_left, panel.size ) );
	
#}  // end GetPanelRect
