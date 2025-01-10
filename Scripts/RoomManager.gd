extends Node

@onready var room_viewer: Node = $RoomViewer
#@onready var main_menu: Room = $MainMenu
@onready var viewer_text: Node = $RoomViewer/Description/DescText

var curr_room : Room = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ChangeRoom( "main_menu" )

#func ChangeRoom( new_room : Node ) -> void:
#	curr_room = new_room
#	if curr_room and viewer_text:
#		viewer_text.text = curr_room.description
#	else:
#		print( "either curr_room or viewer_text not valid" )

func ChangeRoom( new_room : String ) -> void:
	
	if curr_room != null:
		remove_child( curr_room )
		curr_room.queue_free()
		curr_room = null
	
	if curr_room == null:
		curr_room = load( "res://Scenes/" + new_room + ".tscn" ).instantiate()
		add_child( curr_room )
		
	if curr_room and viewer_text:
		viewer_text.text = curr_room.description
	else:
		print( "either curr_room or viewer_text not valid" )

func FindConnectedRoom( room_name : String ) -> Room:
	var rooms = self.get_children()
	for room in rooms:
		if room is Room:
			if room.room_name == room_name:
				return room
	return null
	
# return a room if it's connected to the current room.
func GetConnectedRoom( room_name : String ) -> Room:	
	var parent = null
	if curr_room:
		parent = curr_room.get_parent()
			
	if parent and parent is Room and parent.room_name == room_name:
		return parent 
	else:
		var children = curr_room.get_children()
		for child in children:
			if( child is Room ):
				if( child.room_name == room_name ):
					return child
	return null
	
func FindRoomWithName( node: Room, room_name : String ) -> Room:
	if "room_name" in node:
		if( room_name == node.room_name ):
			return node
			
		for child in node.get_children():
			var result = FindRoomWithName(child, room_name)
			if result:
				return result
	return null

# return a room anywhere on the tree (starting with MainMenu)
#func GetRoom(room_name: String) -> Node:
#	return FindRoomWithName(main_menu, room_name)

func _input( event : InputEvent ) -> void:
	#var choice : Room = null;
	var choice_number = 1
	
	while choice_number <= 9:
		var action_name = "choice" + str(choice_number)
		if event.is_action_pressed( action_name ):
			if curr_room.choices[ choice_number ] != "":
				#choice = GetConnectedRoom( curr_room.choices[ choice_number ] )
				#choice = FindConnectedRoom( curr_room.choices[ choice_number ] )
				#if choice:
					#ChangeRoom( choice )
				ChangeRoom( curr_room.choices[ choice_number ] )
					
					
		choice_number += 1
		
	if event.is_action_pressed("choice0"):
		if curr_room != null:
			remove_child( curr_room )
			curr_room.queue_free()

		get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
