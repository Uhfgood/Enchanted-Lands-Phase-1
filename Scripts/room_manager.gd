extends Node

@onready var room_viewer: Node = $RoomViewer
@onready var viewer_text: Node = $RoomViewer/Description/DescText
@onready var line_edit: Control = $RoomViewer/LineEdit
 
var curr_room = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#{
	if not Engine.is_editor_hint():
		#room_viewer.get_child(0).visible = true
		viewer_text.visible = true

	line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	
	ChangeRoom( "000_Main_Menu" )
	
	
#} // end func _ready()

func LoadRoom( room_name : String ):
	var room = null
	#var tscn_fn = "res://Rooms/" + room_name + ".tscn";
	var json_fn = "res://Rooms/" + room_name + ".json";
	
	#print( "---" )
	#if ResourceLoader.exists( tscn_fn ):
		#var scene = load( tscn_fn )
		#if scene != null:
			#room = scene.instantiate()
			#var doors = room.get_children()
			#for door in doors:
				#if( door is Door ):
					#room.doors.append( door )
			#var str_room_name = str( room.name )
			#var modified_name = str_room_name[ 0 ].to_upper() + str_room_name.substr( 1 )					
			#print( modified_name + " created successfully.")
		#else:
			#print( "Scene couldn't load." )
	if ResourceLoader.exists( json_fn ):
		room = Room.CreateFromJSON( room_name )
	else:
		print( room_name + " does not exist, as either .tscn or .json." )

	return room

func ChangeRoom( room_name : String ):
	var new_room = LoadRoom( room_name )
	if( new_room ):
		if curr_room != null:
			#remove_child( curr_room )
			#curr_room.queue_free()
			curr_room = null
			
		curr_room = new_room
		#add_child( curr_room )
			
		if curr_room and viewer_text:
			viewer_text.text = curr_room.description
		else:
				print( "either curr_room or viewer_text not valid" )
	else:
		print( room_name + " creation unsuccessful." )		

func _on_line_edit_text_submitted(new_text: String):
	print("Command entered: ", new_text)  # Extracted text
	if new_text.begins_with("switch_room "):
		var room_id = new_text.trim_prefix("switch_room ").strip_edges()
		ChangeRoom( room_id )  # Call your room-switching function
	line_edit.clear()  # Clear after submission
	line_edit.release_focus()
	get_viewport().set_input_as_handled()
	line_edit.visible = !line_edit.visible
	
func _input( event : InputEvent ) -> void:
	
	if event.is_action_pressed("console_toggle"):
		line_edit.visible = !line_edit.visible
		if line_edit.visible:
			line_edit.clear()
			line_edit.grab_focus.call_deferred()
		else:
			line_edit.release_focus()
		get_viewport().set_input_as_handled()
		return
	if line_edit.visible and event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		get_viewport().set_input_as_handled()
		return
	if line_edit.visible:
		return
	
	var choice_number = 1
	
	if not curr_room:
		return
		
	while choice_number <= 9:
		var action_name = "choice" + str(choice_number)
		if event.is_action_pressed( action_name ):
				var choice_string = str( choice_number )
				var door = curr_room.GetDoorByChoice( choice_string )
				if door:
					ChangeRoom( door.destination )
				
		choice_number += 1
	
	if event.is_action_pressed("choice0"):
		#if curr_room != null:
		#	remove_child( curr_room )
		#	curr_room.queue_free()
		curr_room = null
		get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
