class_name SeekingWaterState extends State

func _enter():
	# print("Entering SeekingWaterState for Darwin: ", darwin.name) # Debug print
	darwin.target_tile_coords = darwin._find_nearest_resource_source("water")
	if darwin.target_tile_coords == Vector2i.ZERO:
		print("Darwin (", darwin.name, ") needs water but found no sources! Reverting to exploration.")
		change_state("ExplorationState") # Fallback if no water found
		return

func _physics_process(delta: float):
	# If Darwin is no longer thirsty, go back to exploring
	if darwin.current_thirst >= darwin.max_thirst:
		change_state("ExplorationState")
		return
	
	# If target is somehow lost, revert to exploration
	if darwin.target_tile_coords == Vector2i.ZERO:
		change_state("ExplorationState")
		return
		
	# Calculate direction to target tile and move
	var target_world_pos: Vector2 = darwin.terrain.map_to_local(darwin.target_tile_coords) + (darwin.terrain.tile_set.tile_size / 2.0) # Center of the tile
	var direction_to_target: Vector2 = (target_world_pos - darwin.global_position).normalized()
	darwin.velocity = direction_to_target * darwin.speed
	
	# Check if Darwin is close enough to the water source
	if darwin.global_position.distance_to(target_world_pos) < 30: # Small threshold
		change_state("DrinkingState")

func _exit():
	pass
