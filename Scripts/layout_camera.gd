class_name LayoutCamera
extends Camera2D

# --- PAN & ZOOM SETTINGS ---
var is_panning := false
var zoom_speed := 0.1       # Zoom multiplier per wheel tick
var max_zoom := 20.0        # Maximum zoom out
var min_zoom := 0.05        # Will be recalculated dynamically

# Node that contains all rooms
var room_container: Node2D

func _ready() -> void:
	_update_min_zoom()  # Calculate min zoom at start

func _input(event: InputEvent) -> void:
	# --- START / STOP PANNING ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed

		# --- ZOOM (mouse-centered, editor-style) ---
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at_mouse(1 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at_mouse(1 - zoom_speed)

	# --- PAN CAMERA ---
	elif event is InputEventMouseMotion and is_panning:
		# Pan is divided by zoom to stay consistent
		position -= event.relative / zoom

# --- PURE MOUSE-CENTERED ZOOM ---
func _zoom_at_mouse(factor: float) -> void:
	var old_zoom = zoom
	var new_zoom = zoom * factor

	# Clamp zoom dynamically
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)

	# Mouse position in global/world coordinates
	var mouse_pos = get_global_mouse_position()
	position = mouse_pos - (mouse_pos - position) * (new_zoom / old_zoom)

	zoom = new_zoom

# --- NODE2D GLOBAL RECTANGLE ---
func get_node_global_rect(node: Node2D) -> Rect2:
	var global_pos = node.global_position
	var size = Vector2.ZERO

	if node.has_method("get_size"):
		size = node.get_size()
	elif node.has_meta("size"):
		size = node.get_meta("size")
	else:
		for child in node.get_children():
			if child is Sprite2D and child.texture:
				size = child.texture.get_size()
				break

	if size == Vector2.ZERO:
		size = Vector2(64, 64)

	return Rect2(global_pos - size * 0.5, size)

# --- DYNAMIC MIN ZOOM ---
func _update_min_zoom() -> void:
	if not room_container or room_container.get_child_count() == 0:
		return

	var total_rect = get_node_global_rect(room_container.get_child(0))
	for room in room_container.get_children():
		total_rect = total_rect.merge(get_node_global_rect(room))

	var viewport_size = get_viewport_rect().size
	var zoom_x = viewport_size.x / total_rect.size.x
	var zoom_y = viewport_size.y / total_rect.size.y
	min_zoom = min(zoom_x, zoom_y) * 0.9

	if zoom.x < min_zoom:
		zoom = Vector2(min_zoom, min_zoom)
