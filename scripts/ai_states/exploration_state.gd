class_name ExplorationState extends State

var exploration_timer: float = 0.0
var exploration_direction: Vector2 = Vector2.ZERO
@export var angle_offset_range: float = PI / 6 

func _enter():
	exploration_timer = darwin.exploration_move_duration
	_set_new_exploration_step_direction()

func _physics_process(delta: float):
	exploration_timer -= delta
	
	if exploration_timer <= 0:
		if darwin.current_thirst <= darwin.hydration_threshold and darwin.current_hunger <= darwin.hunger_threshold:
			if darwin.current_thirst < darwin.current_hunger:
				change_state("SeekingWaterState")
				return
			else:
				change_state("SeekingFoodState")
				return
		if darwin.current_thirst <= darwin.hydration_threshold:
			change_state("SeekingWaterState")
			return
		if darwin.current_hunger <= darwin.hunger_threshold:
			change_state("SeekingFoodState")
			return
		if darwin.current_thirst >= darwin.reproduction_threshold_thirst and darwin.current_hunger >= darwin.reproduction_threshold_hunger:
			change_state("ReproducingState")
			return
		
		_set_new_exploration_step_direction()
		
	if darwin.global_position.distance_to(darwin.current_global_exploration_goal) < 40: # Threshold in pixels
		print("Reached global exploration goal")
		_set_new_global_exploration_goal()
		
	darwin.velocity = exploration_direction * darwin.speed
	
func _exit():
	pass

#func _set_new_exploration_direction():
	#var random_angle: float = randf() * TAU
	#exploration_direction = Vector2(cos(random_angle), sin(random_angle))
	## Randomize the duration slightly
	#exploration_timer = darwin.exploration_move_duration + randf() * darwin.exploration_move_duration

func _set_new_global_exploration_goal():
	var camera_node: Camera2D = darwin.get_viewport().get_camera_2d()
	
	if camera_node != null:
		var viewport_rect: Rect2 = camera_node.get_viewport_rect()
		
		var viewport_top_left_global = camera_node.global_position - viewport_rect.size / 2.0
		var viewport_bottom_right_global = camera_node.global_position + viewport_rect.size / 2.0

		# Choose a random point within these global bounds
		var random_x = randf_range(viewport_top_left_global.x, viewport_bottom_right_global.x)
		var random_y = randf_range(viewport_top_left_global.y, viewport_bottom_right_global.y)
		darwin.current_global_exploration_goal = Vector2(random_x, random_y)
		print("Darwin (", darwin.name, ") set new global exploration goal: ", darwin.current_global_exploration_goal)
	else:
		print("Warning: Camera2D not found for exploration. Falling back to simple random direction.")
		_set_new_exploration_step_direction() 
		darwin.current_global_exploration_goal = darwin.global_position


# --- MODIFIED: Function to calculate the direction for the current small step ---
func _set_new_exploration_step_direction():
	if darwin.current_global_exploration_goal == Vector2.ZERO or darwin.global_position.distance_to(darwin.current_global_exploration_goal) < 0.1:
		# If no valid goal or already at goal, fall back to just a random direction
		var random_angle: float = randf() * TAU
		exploration_direction = Vector2(cos(random_angle), sin(random_angle))
		return

	# Calculate the true direction towards the global goal
	var direction_to_goal = (darwin.current_global_exploration_goal - darwin.global_position).normalized()
	var base_angle = direction_to_goal.angle()

	# Apply a small random angular offset to the true direction
	var random_offset_angle = randf_range(-angle_offset_range, angle_offset_range)
	var final_angle = base_angle + random_offset_angle

	# Set the exploration_direction for this step
	exploration_direction = Vector2(cos(final_angle), sin(final_angle))
	
	exploration_timer = darwin.exploration_move_duration + randf() * darwin.exploration_move_duration
