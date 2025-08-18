@tool
extends EditorPlugin

var button: Button
var add_button: Button
var remove_button: Button
var layout_tool: Node

func _enter_tree():
	print("---")
	print("Plugin enabled!")
	
	# Create buttons once
	button = Button.new()
	button.text = "Save Room Data"
	button.size = Vector2(130, 30)
	button.visible = true
	print("Button created: " + button.text + " at size: " + str(button.size) + ".")
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, button)
	print("Button added to canvas editor menu.")
	print("Button visibility: " + str(button.visible) + ".")
	
	add_button = Button.new()
	add_button.text = "+"
	add_button.size = Vector2(130, 30)
	add_button.visible = true
	print("Add created: " + add_button.text + " at size: " + str(add_button.size) + ".")
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, add_button)
	print("'+' added to canvas editor menu.")
	print("'+' visibility: " + str(add_button.visible) + ".")
	
	remove_button = Button.new()
	remove_button.text = "-"
	remove_button.size = Vector2(130, 30)
	remove_button.visible = true
	print("Remove created: " + remove_button.text + " at size: " + str(remove_button.size) + ".")
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, remove_button)
	print("'-' added to canvas editor menu.")
	print("'-' visibility: " + str(remove_button.visible) + ".")
	
	# Initialize layout_tool
	layout_tool = get_tree().edited_scene_root
	if not layout_tool or layout_tool.name != "LayoutTool":
		print("No valid LayoutTool scene root available.")
		return
	
	print("Editor map set to: " + layout_tool.name + ".")
	connect_buttons()

func connect_buttons():
	if layout_tool.has_method("_on_save_button_pressed"):
		if not button.is_connected("pressed", Callable(layout_tool, "_on_save_button_pressed")):
			var result = button.connect("pressed", Callable(layout_tool, "_on_save_button_pressed"))
			print("Save Room Data button connection result: " + str(result) + ".")
	
	if layout_tool.has_method("_on_add_room_button_pressed"):
		if not add_button.is_connected("pressed", Callable(layout_tool, "_on_add_room_button_pressed")):
			var result = add_button.connect("pressed", Callable(layout_tool, "_on_add_room_button_pressed"))
			print("Add Room button connection result: " + str(result) + ".")
	
	if layout_tool.has_method("_on_remove_room_button_pressed"):
		if not remove_button.is_connected("pressed", Callable(layout_tool, "_on_remove_room_button_pressed")):
			var result = remove_button.connect("pressed", Callable(layout_tool, "_on_remove_room_button_pressed"))
			print("Remove Room button connection result: " + str(result) + ".")

func _process(delta):
	var current_layout_tool = get_tree().edited_scene_root
	if not current_layout_tool or current_layout_tool.name != "LayoutTool":
		return
	
	if current_layout_tool != layout_tool:
		layout_tool = current_layout_tool
		print("Layout tool updated to: " + layout_tool.name + ".")
		connect_buttons()

func _exit_tree():
	if button:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, button)
		button.queue_free()
		button = null
		print("Removed Save Room Data button.")
	
	if add_button:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, add_button)
		add_button.queue_free()
		add_button = null
		print("Removed Add Room button.")
	
	if remove_button:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, remove_button)
		remove_button.queue_free()
		remove_button = null
		print("Removed Remove Room button.")
