@tool
extends Node2D
class_name CustomLine2D

var start_pos: Vector2 = Vector2.ZERO
var end_pos: Vector2 = Vector2.ZERO
var default_color: Color = Color.WHITE
var width: float = 2.0

func _draw():
	draw_line(start_pos, end_pos, default_color, width)

func set_line(start: Vector2, end: Vector2, color: Color, line_width: float):
	start_pos = start
	end_pos = end
	default_color = color
	width = line_width
	queue_redraw()

func _get_property_list() -> Array:
	var properties = []
	if Engine.is_editor_hint():
		properties.append({
			"name": "position",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		})
		properties.append({
			"name": "start_pos",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		})
		properties.append({
			"name": "end_pos",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		})
		properties.append({
			"name": "default_color",
			"type": TYPE_COLOR,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		})
		properties.append({
			"name": "width",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		})
	return properties
