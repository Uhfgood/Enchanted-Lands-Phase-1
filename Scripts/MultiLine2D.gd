@tool
extends Node2D
class_name MultiLine2D

var lines : Dictionary = {}
var _room_data : Dictionary

var rooms : Dictionary:
	get:
		return _room_data

var line_width = 5.0
var palette = [
	Color.RED, 
	Color.ORANGE, 
	Color.YELLOW, 
	Color.GREEN, 
	Color.CYAN, 
	Color.BLUE, 
	Color.PURPLE, 
	Color.MAGENTA, 
	Color.WHITE 
	]
var col_idx = 0

func InitLines( room_contents ):
#{
	self.z_index = -4096;
	
	_room_data = room_contents;
	lines.clear();
	
	for room in rooms.values():
		UpdateLines( room.id, 5.0, false );
	
	queue_redraw();
#}

func UpdateAllLines( line_thickness : float = 5.0 ):
#{
	for room in rooms.values():
		UpdateLines( room.id, line_thickness, false )
	
	queue_redraw()

#}  // end func UpdateAllLines()

func UpdateLines( room_id : String, thickness : float = 5.0, do_redraw : bool = true ):
#{
	var room = rooms[ room_id ]
	
	# Make sure it's valid
	if( !room ):
		return;

	line_width = thickness;

	var panel = room.get_node_or_null( "Panel" );
	var vbox = panel.get_node_or_null( "VBox" );
	var name_label = vbox.get_node_or_null( "NameLabel" );

	var separator_y = 0;
	var center_y = 0;
	if( name_label and vbox and panel ):
	#{
		# Calculate the vertical position of the Separator
		var name_label_height = name_label.get_minimum_size().y;
		var separation = vbox.get_theme_constant("separation");
		separator_y = name_label_height + separation;  # Separator's top edge relative to VBox

		# Adjust for VBox's position within the Panel
		separator_y += vbox.position.y;
		center_y = panel.size.y / 2;
	#}
	
	# Since we do have a room, read the door data
	var door_data = room.GetDoorData();
	# If there is no door_data, then no need to update the lines
	if( door_data.size() < 1 ):
		return;
	
	# If it doesn't already have a room entry, then create one
	if( not lines.has( room.id ) ):
		lines[ room.id ] = {}
		
	# clean up "ghost" lines (remove lines that no longer exist in the door destinations
	var line_collection = lines[ room.id ]
	var current_doors = {}
	for door in door_data:
		current_doors[ door.destination ] = true

	for dest_id in line_collection.keys():
		if( not current_doors.has( dest_id ) ):
			line_collection.erase( dest_id )
	
	# Now we've got both door data, and a lines dictionary, even if empty.
	
	for door in door_data:
	#{
		# Make sure the destination room is there else skip over it
		if( not rooms.has( door.destination ) ):
			continue;
						
		var dest_room : LayoutRoom = rooms[ door.destination ];
		
		#var room_pos = Vector2( room.position.x, ( room.position.y - separator_y ) + center_y );
		#var dest_pos = Vector2( dest_room.position.x, ( dest_room.position.y - separator_y ) + center_y );
		var start_pos = room.GetCenterPos(); #room_pos; #room.position
		var end_pos = dest_room.GetCenterPos(); #dest_pos; #dest_room.position
		#print( "room: " + room.id + ", room position = " + str( room.position ) + ", room center = " + str( room.GetCenterPos() ) )
		#print( "dest room: " + dest_room.id + ", dest position = " + str( dest_room.position ) + ", dest room center = " + str( dest_room.GetCenterPos() ) )
		
		if not line_collection.has( door.destination ):
			# Assign next color from palette, cycle through palette
			var door_col = palette[ col_idx % palette.size() ];
			col_idx += 1
			line_collection[ door.destination ] = {
				"color" : door_col,
				"start" : start_pos,
				"end" : end_pos
			}
		else:
			# Update positions but keep existing color
			line_collection[ door.destination ][ "start" ] = start_pos;
			line_collection[ door.destination ][ "end" ] = end_pos;
	
	# go through each inbound link
	for inbound in room.inbound_rooms:
	#{
		# make sure we have an entry for the source room
		if( lines.has( inbound ) ):
		#{
			# check to see that the room lines collection has an entry for the current room
			# and then update the end position of that particular line, to the room's current position.
			if( lines[ inbound ].has( room.id ) ):
				lines[ inbound ][ room.id ][ "end" ] = room.GetCenterPos(); #room.position
		#}
	#}
		
	if( do_redraw ):
		queue_redraw();
		
#}  // end UpdateLines

func ClearLines():
	lines.clear()
	queue_redraw()

func _draw():
#{
	for source_id in lines.keys():
	#{
		var line_collection = lines[ source_id ]
		for dest_id in line_collection.keys():
		#{
			var line_data = line_collection[ dest_id ] 
			draw_line( 
				line_data[ "start" ], 
				line_data[ "end" ], 
				line_data[ "color" ], 
				line_width )
			
		#}  // end for dest_id
		
	#} // end for source_id
	
#}  // end _draw
