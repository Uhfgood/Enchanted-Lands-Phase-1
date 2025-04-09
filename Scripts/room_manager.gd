extends Node

@onready var room_viewer: Node = $RoomViewer
@onready var viewer_text: Node = $RoomViewer/Description/DescText

var curr_room = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ChangeRoom( "lv000sn00-main-menu-plvXXXsnXX" )

func LoadRoom( room_name : String ):
	var room = null
	var tscn_fn = "res://Rooms/" + room_name + ".tscn";
	var json_fn = "res://Rooms/" + room_name + ".json";
	
	print( "---" )
	if ResourceLoader.exists( tscn_fn ):
		var scene = load( tscn_fn )
		if scene != null:
			room = scene.instantiate()
			var doors = room.get_children()
			for door in doors:
				if( door is Door ):
					room.doors.append( door )
			var str_room_name = str( room.name )
			var modified_name = str_room_name[ 0 ].to_upper() + str_room_name.substr( 1 )					
			print( modified_name + " created successfully.")
		else:
			print( "Scene couldn't load." )
	elif ResourceLoader.exists( json_fn ):
		room = Room.CreateFromJSON( room_name )
	else:
		print( room_name + " does not exist, as either .tscn or .json." )

	return room


func ChangeRoom( room_name : String ):
	var new_room = LoadRoom( room_name )
	if( new_room ):
		if curr_room != null:
			remove_child( curr_room )
			curr_room.queue_free()
			curr_room = null
			
		curr_room = new_room
		add_child( curr_room )
			
		if curr_room and viewer_text:
			viewer_text.text = curr_room.description
		else:
				print( "either curr_room or viewer_text not valid" )
	else:
		print( room_name + " creation unsuccessful." )		

func _input( event : InputEvent ) -> void:
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
		if curr_room != null:
			remove_child( curr_room )
			curr_room.queue_free()

		get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
