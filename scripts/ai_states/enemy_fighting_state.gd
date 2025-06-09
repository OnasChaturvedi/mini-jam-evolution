extends State
class_name EnemyFightingState

# --- Internal Variables ---
var target_darwin: Darwin = null # The specific Darwin this enemy is targeting
var attack_cooldown: float = 0.0 # Timer for attack intervals
@export var base_attack_interval: float = 1.0 # Default attack interval in seconds

func _enter():
	print("fighting state entered")
	attack_cooldown = 0.0 

func _physics_process(delta: float) -> void:
	if darwin.get_tree().get_nodes_in_group("creatures").size() <= 0: # Assuming game_manager tracks this
		darwin.change_state("ExplorationState") 
		return

	if not is_instance_valid(target_darwin): # If no target or target died
		target_darwin = _find_closest_darwin_target()
		if not is_instance_valid(target_darwin):
			darwin.change_state("ExplorationState")
			return

	# --- Movement & Attack Logic ---
	var distance_to_target = darwin.global_position.distance_to(target_darwin.global_position)
	
	if distance_to_target <= darwin.attack_range_tiles * darwin.terrain.tile_set.tile_size.x:
		darwin.velocity = Vector2.ZERO
		_handle_attack(delta)
	else:
		# Move towards the target Darwin
		var move_vector = (target_darwin.global_position - darwin.global_position).normalized()
		darwin.velocity = move_vector * darwin.speed

func _exit():
	target_darwin = null

# --- Fighting State Specific Helpers ---

func _find_closest_darwin_target() -> CharacterBody2D:
	var closest_darwin: Darwin = null
	var min_distance_sq = INF # Initialize with infinity

	# Iterate through all Darwins in the "darwins" group
	for darwin in darwin.get_tree().get_nodes_in_group("creatures"):
		if is_instance_valid(darwin): # Ensure it's a valid, alive Darwin
			var distance_sq = darwin.global_position.distance_squared_to(darwin.global_position)
			if distance_sq < min_distance_sq:
				min_distance_sq = distance_sq
				closest_darwin = darwin
	
	return closest_darwin

func _handle_attack(delta: float):
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		if is_instance_valid(target_darwin):
			# Apply damage to the target Darwin
			var damage_amount = darwin.attack_damage # Assuming enemy has attack_damage trait
			target_darwin.take_damage(damage_amount, darwin)
			# print("Enemy attacked Darwin! Damage: %s, Darwin Health: %s" % [damage_amount, target_darwin.health])
			
			# Reset cooldown
			attack_cooldown = base_attack_interval
			
			if target_darwin.current_health <= 0:
				target_darwin = null
				change_state("ExplorationState")
			
			# Optional: Add visual/audio feedback for attack (e.g., animation, sound)
		else:
			target_darwin = null
			change_state("ExplorationState")
