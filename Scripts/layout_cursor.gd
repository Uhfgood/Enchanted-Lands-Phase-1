extends Node2D

func _ready():
	z_index = 999  # Float above basically everything
	Input.set_mouse_mode( Input.MOUSE_MODE_HIDDEN )
	
func _draw():
	var c = Vector2.ZERO
	draw_line(c - Vector2(5, 0), c + Vector2(5, 0), Color.WHITE, 2)
	draw_line(c - Vector2(0, 5), c + Vector2(0, 5), Color.WHITE, 2)
	draw_line(c - Vector2(1, 0), c + Vector2(1, 0), Color.RED, 2)

func _process( _delta ):
	position = get_global_mouse_position()
	queue_redraw()

func _exit_tree():
	Input.set_mouse_mode( Input.MOUSE_MODE_VISIBLE );
