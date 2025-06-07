class_name ExplorationState extends State

var exploration_timer: float = 0.0
var exploration_direction: Vector2 = Vector2.ZERO

func _enter():
	# print("Entering ExplorationState for Darwin: ", darwin.name) # Debug print
	_set_new_exploration_direction()

func _physics_process(delta: float):
	# Continue exploring logic
	exploration_timer -= delta
	if exploration_timer <= 0:
		if darwin.current_thirst <= darwin.hydration_threshold:
			change_state("SeekingWaterState")
			return
		if darwin.current_hunger <= darwin.hunger_threshold:
			change_state("SeekingFoodState")
			return
		if darwin.current_thirst >= darwin.reproduction_threshold_thirst and darwin.current_hunger >= darwin.reproduction_threshold_hunger:
			change_state("ReproducingState")
			return
		
		_set_new_exploration_direction()
	
	darwin.velocity = exploration_direction * darwin.speed
	
func _exit():
	pass

func _set_new_exploration_direction():
	var random_angle: float = randf() * TAU # TAU is 2 * PI (a full circle in radians)
	exploration_direction = Vector2(cos(random_angle), sin(random_angle))
	# Randomize the duration slightly to make movement less predictable
	exploration_timer = darwin.exploration_move_duration + randf() * darwin.exploration_move_duration
