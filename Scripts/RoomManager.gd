extends Node

@onready var room_viewer: Node = $RoomViewer
@onready var viewer_text: Node = $RoomViewer/Description/DescText

var curr_room : Room = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	curr_room = LoadRoom( "main_menu" )
	ChangeRoom( "main_menu" )

func LoadRoom( room_name : String ) -> Room:
	var room = null
	var filename = "res://Scenes/" + room_name + ".tscn";
	if ResourceLoader.exists( filename ):
		var scene = load( filename )
		if scene != null:
			room = scene.instantiate()
		else:
			print( "Couldn't load " + filename + ", trying json." )
			room = null
			room = Room.CreateRoomFromJSON( room_name )
	else:
		print( "The file: " + filename + " doesn't exist.  Trying json." )
		room = null
		room = Room.CreateRoomFromJSON( room_name )
		
	return room
	
func ChangeRoom( room_name : String ) -> void:
	var new_room = LoadRoom( room_name )
	if curr_room != null:
		remove_child( curr_room )
		curr_room.queue_free()
		curr_room = null
		
		if curr_room == null:
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

	var doors = curr_room.get_children()
	
	while choice_number <= 9:
		var action_name = "choice" + str(choice_number)
		if event.is_action_pressed( action_name ):
			for door in doors:
				if choice_number == int( door.choice ):
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
