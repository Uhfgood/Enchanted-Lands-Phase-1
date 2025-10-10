@tool
extends Node2D
class_name MultiLine2D

var lines : Dictionary = {}
var _room_data : Dictionary

var rooms : Dictionary:
	get:
		return( _room_data );

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
		UpdateLines( room.id, line_thickness, false );
	
	queue_redraw();

#}  // end func UpdateAllLines()

func UpdateLines( room_id : String, thickness : float = 5.0, do_redraw : bool = true ):
#{
	if( !rooms ):
		return;
		
	var room = null;
	if( rooms.has( room_id ) ):
		room = rooms[ room_id ]
	
	# Make sure it's valid
	if( !room ):
		return;

	#print( "Updating lines for ", room_id );
	line_width = thickness;
	
	# Since we do have a room, read the door data
	var door_data = room.GetDoorData();

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
		
		var start_pos = room.global_position;
		var end_pos = dest_room.global_position;
		
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
	
	#}  // end for door
	
	# go through each inbound link
	for inbound in room.inbound_rooms:
	#{
		#print( "inbound for " + room.id + " = " + inbound );
		# make sure we have an entry for the source room
		if( lines.has( inbound ) ):
		#{
			# check to see that the room lines collection has an entry for the current room
			# and then update the end position of that particular line, to the room's current position.
			if( lines[ inbound ].has( room.id ) ):
				lines[ inbound ][ room.id ][ "end" ] = room.global_position;
				#print( "Inbound updating ", room.id );
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
