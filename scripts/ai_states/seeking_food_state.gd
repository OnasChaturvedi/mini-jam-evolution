class_name SeekingFoodState extends State

func _enter():
	# print("Entering SeekingFoodState for Darwin: ", darwin.name) # Debug print
	darwin.target_tile_coords = darwin._find_nearest_resource_source("food") # Assuming "food" is a custom data value
	if darwin.target_tile_coords == Vector2i.ZERO:
		#print("Darwin (", darwin.name, ") needs food but found no sources! Reverting to exploration.")
		change_state("ExplorationState") # Fallback if no food found
		return

func _physics_process(delta: float):
	# If Darwin is no longer hungry, go back to exploring
	if darwin.current_hunger >= darwin.max_hunger:
		change_state("ExplorationState")
		return
	
	# If target is somehow lost, revert to exploration
	if darwin.target_tile_coords == Vector2i.ZERO:
		change_state("ExplorationState")
		return
		
	# Calculate direction to target tile and move
	var target_world_pos: Vector2 = darwin.terrain.map_to_local(darwin.target_tile_coords) + (darwin.terrain.tile_set.tile_size / 2.0)
	var direction_to_target: Vector2 = (target_world_pos - darwin.global_position).normalized()
	darwin.velocity = direction_to_target * darwin.speed
	
	# Check if Darwin is close enough to the food source
	if darwin.global_position.distance_to(target_world_pos) < 30:
		change_state("EatingState")

func _exit():
	pass
