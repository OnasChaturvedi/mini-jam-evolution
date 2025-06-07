class_name DrinkingState extends State

func _enter():
	# print("Entering DrinkingState for Darwin: ", darwin.name) # Debug print
	darwin.velocity = Vector2.ZERO # Stop moving to drink
	darwin.target_tile_coords = Vector2i.ZERO # Clear the target coordinates

func _physics_process(delta: float):
	# Restore thirst over time
	darwin.current_thirst = min(darwin.max_thirst, darwin.current_thirst + darwin.hydration_rate * delta)
	
	# If fully hydrated, go back to exploring
	if darwin.current_thirst >= darwin.max_thirst:
		change_state("ExplorationState")

func _exit():
	pass
