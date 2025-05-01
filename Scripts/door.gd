@tool
class_name Door extends Node2D

@export var choice: String = "0"
@export var destination: String = "blank_room"
@export var id: String = "drXXX"
var start_mouse_position: Vector2 = Vector2.ZERO
var start_room_position: Vector2 = Vector2.ZERO
var color_rect_initial_position: Vector2 = Vector2(-10, -10) # Initial ColorRect position
var initial_position: Vector2 = Vector2.ZERO # Initial local position of Door relative to Room
var is_dragging: bool = false # Flag to track dragging state

static func create(ident: String, ch: String, dest: String, door_name: String) -> Door:
	var new_door = Door.new()
	new_door.id = ident
	new_door.choice = ch
	new_door.destination = dest
	new_door.name = door_name
	return new_door

func _enter_tree():
	if Engine.is_editor_hint():
		print("Door._enter_tree: Initializing door: ", name, " (ID: ", id, ", Destination: ", destination, ")")
		print("  Is inside tree: ", is_inside_tree())
		var parent = get_parent()
		print("  Parent: ", parent.name if parent else "null")
		var owner_value = owner
		print("  Owner: ", owner_value.name if owner_value else "null")
		print("  Stack: ", get_stack())
		# Initialize start_mouse_position
		var viewport = get_viewport()
		if viewport:
			start_mouse_position = viewport.get_mouse_position()
		else:
			start_mouse_position = Vector2.ZERO
		# Add ColorRect for visualization
		var color_rect = ColorRect.new()
		color_rect.name = "DoorVisual"
		color_rect.size = Vector2(20, 20) # Small square for Door
		color_rect.color = Color(1, 0, 0) # Red for visibility (customize as needed)
		color_rect.position = color_rect_initial_position # Center on Door's origin
		color_rect.visible = true # Ensure ColorRect is visible
		add_child(color_rect)
		color_rect.owner = get_tree().edited_scene_root
		print("  Added ColorRect to door: ", name)

func _ready():
	if Engine.is_editor_hint():
		print("Door._ready: Initializing door: ", name, " (ID: ", id, ", Destination: ", destination, ")")
		print("  Is inside tree: ", is_inside_tree())
		var parent = get_parent()
		print("  Parent: ", parent.name if parent else "null")
		var owner_value = owner
		print("  Owner: ", owner_value.name if owner_value else "null")
		print("  Stack: ", get_stack())
		initial_position = position # Store initial local position
		if parent:
			start_room_position = parent.global_position
		# Ensure start_mouse_position is set if not already
		var viewport = get_viewport()
		if viewport and start_mouse_position == Vector2.ZERO:
			start_mouse_position = viewport.get_mouse_position()

func _process(_delta):
	if Engine.is_editor_hint():
		var parent = get_parent()
		if not parent is Room:
			print("Warning: Door ", name, " has non-Room parent: ", parent.name if parent else "null")
			return
		
		var color_rect = get_node_or_null("DoorVisual")
		if not color_rect:
			print("Warning: ColorRect 'DoorVisual' not found for Door ", name)
			return
		
		# Get the currently selected node
		var editor_selection = EditorInterface.get_selection()
		var selected_nodes = editor_selection.get_selected_nodes()
		var selected_node = null
		if not selected_nodes.is_empty():
			selected_node = selected_nodes[0]
		
		# Get current mouse position
		var viewport = get_viewport()
		if not viewport:
			return
		var current_mouse_pos = viewport.get_mouse_position()
		
		# Check if the left mouse button is released
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and is_dragging:
			is_dragging = false
			print("Stopped dragging ", name, " (mouse button released)")
		
		# Check if the node is being dragged (selected, mouse moved, and dragging)
		if selected_node in [self, color_rect] and is_dragging:
			# Calculate total mouse delta from start of drag
			var mouse_delta = current_mouse_pos - start_mouse_position
			print("Mouse moved by total delta: ", mouse_delta)
			# Move the Room to the position where the Door should be
			parent.global_position = start_room_position + mouse_delta
			# Reset Door and ColorRect local positions
			position = initial_position
			color_rect.position = color_rect_initial_position
			print("Room ", parent.name, " position updated to: ", parent.global_position, ", Door local position: ", position)
		elif selected_node in [self, color_rect] and current_mouse_pos != start_mouse_position and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# Start dragging only if the mouse button is pressed and the mouse has moved
			is_dragging = true
			start_mouse_position = current_mouse_pos
			start_room_position = parent.global_position
			print("Started dragging ", "Door" if selected_node == self else "ColorRect", " of ", name)
		else:
			start_mouse_position = current_mouse_pos
