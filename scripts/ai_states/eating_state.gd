class_name EatingState extends State

func _enter():
	darwin.velocity = Vector2.ZERO # Stop moving to eat
	darwin.target_tile_coords = Vector2i.ZERO # Clear the target coordinates

func _physics_process(delta: float):
	# Restore hunger over time
	darwin.current_hunger = min(darwin.max_hunger, darwin.current_hunger + darwin.satiation_rate * delta)
	
	# If fully satiated, go back to exploring
	if darwin.current_hunger >= darwin.max_hunger:
		change_state("ExplorationState")

func _exit():
	pass
