# States/ReproducingState.gd
class_name ReproducingState extends State

var reproduction_timer: float = 0.0

func _enter():
	# print("Entering ReproducingState for Darwin: ", darwin.name)
	darwin.velocity = Vector2.ZERO # Stop moving during reproduction
	reproduction_timer = darwin.reproduction_time # Initialize timer for reproduction duration

func _physics_process(delta: float):
	# Gradually consume resources during the reproduction process
	# This ensures the cost is spread out over the reproduction_time
	darwin.current_thirst = max(0, darwin.current_thirst - darwin.reproduction_thirst_cost / darwin.reproduction_time * delta)
	darwin.current_hunger = max(0, darwin.current_hunger - darwin.reproduction_hunger_cost / darwin.reproduction_time * delta)

	# Check if Darwin runs out of resources mid-reproduction
	if darwin.current_thirst <= 0 or darwin.current_hunger <= 0:
		print("Darwin (", darwin.name, ") aborted reproduction due to critical resource levels!")
		change_state("ExplorationState") # Revert to exploration, might lead to death soon
		return

	reproduction_timer -= delta
	
	# If reproduction time is over, spawn the new Darwin
	if reproduction_timer <= 0:
		darwin._spawn_new_creature() # Call the spawning method on the Darwin instance
		change_state("ExplorationState") # Go back to exploring after successful reproduction

func _exit():
	pass
