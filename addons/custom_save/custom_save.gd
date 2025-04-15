@tool
extends EditorPlugin

var button: Button

func _enter_tree():
	print("Plugin enabled!")
	button = Button.new()
	button.text = "Save Room Data"
	button.size = Vector2(130, 30)
	button.visible = true
	print("Button created: ", button.text, " at size: ", button.size)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, button)
	print("Button added to canvas editor menu")
	print("Button visibility: ", button.visible)
	var editor_map = get_tree().edited_scene_root
	if editor_map and editor_map.has_method("_on_save_button_pressed"):
		button.connect("pressed", Callable(editor_map, "_on_save_button_pressed"))

func _process(delta):
	if Engine.is_editor_hint():
		var editor_map = get_tree().edited_scene_root
		#print("Editor map instance: ", editor_map)  # Debug instance
		if editor_map and editor_map.has_method("_on_save_button_pressed"):
			if not button.is_connected("pressed", Callable(editor_map, "_on_save_button_pressed")):
				button.connect("pressed", Callable(editor_map, "_on_save_button_pressed"))
				print("Reconnected to editor_map")

func _on_button_pressed():
	print("Button pressed!")

func _exit_tree():
	if button:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, button)
