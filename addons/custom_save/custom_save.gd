@tool
extends EditorPlugin

var button: Button
var add_button: Button
var remove_button: Button

var editor_map: Node

func _enter_tree():
#{
	print( "---" )
	print( "Plugin enabled!" )
	
	# Initialize editor_map
	editor_map = get_tree().edited_scene_root
	if not editor_map:
		print( "No edited scene root available." )
	else:
		print( "Editor map set to: " + editor_map.name + "." )
	
	# Save Room Data button
	button = Button.new()
	button.text = "Save Room Data"
	button.size = Vector2( 130, 30 )
	button.visible = true
	print( "Button created: " + button.text + " at size: " + str( button.size ) + "." )
	add_control_to_container( CONTAINER_CANVAS_EDITOR_MENU, button )
	print( "Button added to canvas editor menu." )
	print( "Button visibility: " + str( button.visible ) + "." )
	
	if editor_map and editor_map.has_method( "_on_save_button_pressed" ):
		var result = button.connect( "pressed", 
			Callable( editor_map, "_on_save_button_pressed" ) )
		print( "Save Room Data button connection result: " + str( result ) + "." )
	
	# Add Room button
	add_button = Button.new()
	add_button.text = "+"
	add_button.size = Vector2( 130, 30 )
	add_button.visible = true
	print( "Add created: " + add_button.text + " at size: " + str( add_button.size ) + "." )
	add_control_to_container( CONTAINER_CANVAS_EDITOR_MENU, add_button )
	print( "'+' added to canvas editor menu." )
	print( "'+' visibility: " + str( add_button.visible ) + "." )
	
	if editor_map and editor_map.has_method( "_on_add_room_button_pressed" ):
		var result = add_button.connect( "pressed", 
			Callable( editor_map, "_on_add_room_button_pressed" ) )
		print( "Add Room button connection result: " + str( result ) + "." )
	
	# Remove Room button
	remove_button = Button.new()
	remove_button.text = "-"
	remove_button.size = Vector2( 130, 30 )
	remove_button.visible = true
	print( "Remove created: " + remove_button.text + " at size: " + str( remove_button.size ) + "." )
	add_control_to_container( CONTAINER_CANVAS_EDITOR_MENU, remove_button )
	print( "'-' added to canvas editor menu." )
	print( "'-' visibility: " + str( remove_button.visible ) + "." )
	
	if editor_map and editor_map.has_method( "_on_remove_room_button_pressed" ):
		var result = remove_button.connect( "pressed", 
			Callable( editor_map, "_on_remove_room_button_pressed" ) )
		print( "Remove Room button connection result: " + str( result ) + "." )
	
	# Connect selection_changed signal from EditorSelection
	if editor_map and editor_map.has_method( "_on_selection_changed" ):
	#{
		var editor_interface = get_editor_interface()
		var editor_selection = editor_interface.get_selection()
		editor_selection.connect( "selection_changed", 
			Callable( editor_map, "_on_selection_changed" ) )
		print( "Selection changed signal connected to editor_map." )
	#}
	else:
		print( "Editor map or _on_selection_changed method not found." )

#}  // end func _enter_tree()

func _process(delta):
#{
	if Engine.is_editor_hint():
		var current_editor_map = get_tree().edited_scene_root
		
		if current_editor_map and current_editor_map.has_method("_on_save_button_pressed"):
			if not button.is_connected("pressed", Callable(current_editor_map, "_on_save_button_pressed")):
				button.connect("pressed", Callable(current_editor_map, "_on_save_button_pressed"))
				#print("Reconnected Save Room Data button to editor_map.")
		
		if current_editor_map and current_editor_map.has_method("_on_add_room_button_pressed"):
			if not add_button.is_connected("pressed", Callable(current_editor_map, "_on_add_room_button_pressed")):
				add_button.connect("pressed", Callable(current_editor_map, "_on_add_room_button_pressed"))
				#print("Reconnected Add Room button to editor_map.")
		
		if current_editor_map and current_editor_map.has_method("_on_remove_room_button_pressed"):
			if not remove_button.is_connected("pressed", Callable(current_editor_map, "_on_remove_room_button_pressed")):
				remove_button.connect("pressed", Callable(current_editor_map, "_on_remove_room_button_pressed"))
				#print("Reconnected Remove Room button to editor_map.")

		if current_editor_map and current_editor_map.has_method("_on_selection_changed"):
			# Check if a removal is in progress before reconnecting
			if "is_removing_room" in current_editor_map and current_editor_map.is_removing_room:
				#print("Skipping signal reconnection during room removal.")
				return
			
			var editor_interface = get_editor_interface()
			var editor_selection = editor_interface.get_selection()
			if not editor_selection.is_connected("selection_changed", Callable(current_editor_map, "_on_selection_changed")):
				editor_selection.connect("selection_changed", Callable(current_editor_map, "_on_selection_changed"))
				#print("Reconnected editor selector.")
						
#}  // end _process()

func _on_button_pressed():
#{
	print( "Button pressed!" )

#}  // end func _on_button_pressed()

func _exit_tree():
#{
	if button:
		remove_control_from_container( CONTAINER_CANVAS_EDITOR_MENU, button )
		button.queue_free()
		button = null
		print( "Removed Save Room Data button." )
	
	if add_button:
		remove_control_from_container( CONTAINER_CANVAS_EDITOR_MENU, add_button )
		add_button.queue_free()
		add_button = null
		print( "Removed Add Room button." )
	
	if remove_button:
		remove_control_from_container( CONTAINER_CANVAS_EDITOR_MENU, remove_button )
		remove_button.queue_free()
		remove_button = null
		print( "Removed Remove Room button." )
	
	if editor_map and editor_map.has_method( "_on_selection_changed" ):
	#{
		var editor_interface = get_editor_interface()
		var editor_selection = editor_interface.get_selection()
		editor_selection.disconnect( "selection_changed", 
			Callable( editor_map, "_on_selection_changed" ) )
		print( "Selection changed signal disconnected from editor_map." )
	#}
	else:
		print( "Editor map or _on_selection_changed method not found." )

#}  // end func _exit_tree()
