extends CharacterBody2D
class_name Enemy

@export var speed: float = 120.0

# --- Core Needs ---
@export var max_health: float = 130.0

@export var max_thirst: float = 100.0
@export var thirst_depletion_rate: float = 2.0 # How much thirst depletes per second
@export var hydration_rate: float = 30.0 # How much thirst is restored per second when drinking
@export var hydration_threshold: float = 50.0 # Thirst level at which Darwin starts seeking water

@export var max_hunger: float = 100.0
@export var hunger_depletion_rate: float = 1.0 # How much hunger depletes per second
@export var satiation_rate: float = 25.0 # How much hunger is restored per second when eating
@export var hunger_threshold: float = 60.0 # Hunger level at which Darwin starts seeking food

@export var reproduction_thirst_cost: float = 40.0   # Thirst consumed during reproduction
@export var reproduction_hunger_cost: float = 40.0   # Hunger consumed during reproduction
@export var reproduction_time: float = 2.0           # How long reproduction takes (animation/delay)
@export var reproduction_threshold_thirst: float = 80.0 # Thirst level needed to consider reproducing
@export var reproduction_threshold_hunger: float = 80.0 # Hunger level needed to consider reproducing
var creature_scene_path: String = "res://scenes/enemy.tscn"
@export var max_age: float = 20

@export var attack_damage: float = 40.0
@export var attack_range_tiles: int = 2

@export var exploration_move_duration: float = 0.5 # How long to move in one direction during exploration
var current_global_exploration_goal: Vector2 = Vector2.ZERO 

@onready var terrain: TileMapLayer = $"../../World/Terrain"

var current_state_object: State = null # Holds the actual instantiated state object
var current_state_name: String = "" # Stores the string name of the current state

const EXPLORATION_STATE = preload("res://scripts/ai_states/exploration_state.gd")
const SEEKING_WATER_STATE =preload("res://scripts/ai_states/seeking_water_state.gd")
const DRINKING_STATE = preload("res://scripts/ai_states/drinking_state.gd")
const SEEKING_FOOD_STATE = preload("res://scripts/ai_states/seeking_food_state.gd")
const EATING_STATE = preload("res://scripts/ai_states/eating_state.gd")
const REPRODUCING_STATE = preload("res://scripts/ai_states/reproducing_state.gd")
const FIGHTING_STATE = preload("res://scripts/ai_states/enemy_fighting_state.gd")

const DEATH_POINT_VALUES = {
	"thirst": 3,
	"hunger": 5,
	"age": 10
}

# --- Darwin Attributes (Current Values) ---
# These are accessed by the state objects via the 'darwin' reference
var current_thirst: float = 0.0
var current_hunger: float = 0.0
var current_health: float = 0.0
var current_age: float = 0.0
var current_tiledata: TileData
var target_tile_coords: Vector2i = Vector2i.ZERO # Stores the coordinates of the tile the Darwin is moving towards


func _ready() -> void:
	if terrain == null:
		print("Tilemap 'Terrain' not found for Darwin: ", name, ". Please ensure it's correctly linked in the editor.")
		set_physics_process(false) # Disable processing if essential nodes are missing
		return
	
	current_thirst = max_thirst * max(0.4, randf())
	current_hunger = max_hunger * max(0.4, randf())
	current_health = max_health
	max_age *= randf_range(0.5, 1.5)
	
	current_global_exploration_goal = global_position
	change_state("ExplorationState")


func _physics_process(delta: float) -> void:
	get_current_tiledata()
	_update_stats(delta)
	
	if current_state_object != null:
		current_state_object._physics_process(delta)
	
	apply_tile_attributes()
	
	move_and_slide()
	#queue_redraw()


# This is the central function for changing states
func change_state(new_state_name: String):
	if current_state_name == new_state_name:
		return
	
	if current_state_object != null:
		current_state_object._exit()
	
	var new_state_script = null
	match new_state_name:
		"ExplorationState": new_state_script = EXPLORATION_STATE
		"SeekingWaterState": new_state_script = SEEKING_WATER_STATE
		"DrinkingState": new_state_script = DRINKING_STATE
		"SeekingFoodState": new_state_script = SEEKING_FOOD_STATE
		"EatingState": new_state_script = EATING_STATE
		"ReproducingState": new_state_script = REPRODUCING_STATE
		"FightingState": new_state_script = FIGHTING_STATE
		_:
			print("Error: State '%s' not found or not preloaded!" % new_state_name)
			return
	
	if new_state_script != null:
		current_state_object = new_state_script.new(self)
		current_state_name = new_state_name
		current_state_object._enter()
	else:
		print("Failed to instantiate state: ", new_state_name)


func take_damage(damage_amt: float):
	current_health -= damage_amt
	print("ouch my hp is ", current_health)
	
	
func get_current_tiledata() -> void:
	current_tiledata = terrain.get_cell_tile_data(terrain.local_to_map(global_position))


func apply_tile_attributes() -> void:
	if current_tiledata:
		velocity *= current_tiledata.get_custom_data("movement_modifier")
	
	
func _find_nearest_resource_source(resource_type: String) -> Vector2i:
	if terrain == null:
		return Vector2i.ZERO

	var current_tile_coords: Vector2i = terrain.local_to_map(global_position)
	var resource_coords: Vector2i = Vector2i.ZERO
	var min_distance_sq: float = INF

	var tile_search_radius: int = 5 # How far to search for resources
	
	if resource_type == "food":
		var search_radius_world: float = terrain.tile_set.tile_size.x * tile_search_radius # Convert tile radius to world units
		
		# Get all nodes in the "food_source" group
		var food_bushes = get_tree().get_nodes_in_group("food_source")
		var chosen_bush: BerryBush
		
		for bush in food_bushes:
			if bush is BerryBush:
				if !bush.has_berries():
					continue
					
				var bush_world_pos = bush.global_position
				var dist_sq = global_position.distance_squared_to(bush_world_pos)
				
				if dist_sq < min_distance_sq and dist_sq < search_radius_world * search_radius_world:
					min_distance_sq = dist_sq
					resource_coords = terrain.local_to_map(bush_world_pos)
					chosen_bush = bush
		if chosen_bush:
			chosen_bush.feed()
	else:
		for y_offset in range(-tile_search_radius, tile_search_radius + 1):
			for x_offset in range(-tile_search_radius, tile_search_radius + 1):
				var check_coords: Vector2i = current_tile_coords + Vector2i(x_offset, y_offset)
				
				var tile_data: TileData = terrain.get_cell_tile_data(check_coords)
				if tile_data:
					var terrain_type: String = tile_data.get_custom_data("terrain_type")
					if terrain_type == resource_type:
						var dist_sq = current_tile_coords.distance_squared_to(check_coords)
						if dist_sq < min_distance_sq:
							min_distance_sq = dist_sq
							resource_coords = check_coords
	
	return resource_coords


func _update_stats(delta: float):
	# Thirst depletion
	current_thirst = max(0, current_thirst - thirst_depletion_rate * delta)
	# Hunger depletion
	current_hunger = max(0, current_hunger - hunger_depletion_rate * delta)
	# Aging
	current_age = min(max_age, current_age + delta)
	
	if current_health <= 0 or current_thirst <= 0 or current_hunger <= 0 or current_age >= max_age:
		AudioManager.play_die_sound()
		call_deferred("queue_free")


func _spawn_new_creature():
	if creature_scene_path.is_empty():
		print("Reproduction failed: Darwin scene path is empty!")
		return

	var creature_scene: PackedScene = load(creature_scene_path)
	if not creature_scene:
		print("Reproduction failed: Could not load Darwin scene from path: ", creature_scene_path)
		return

	# Consume resources for reproduction
	current_thirst = max(0, current_thirst - reproduction_thirst_cost)
	current_hunger = max(0, current_hunger - reproduction_hunger_cost)

	var new_darwin_instance = creature_scene.instantiate()
	
	add_sibling(new_darwin_instance)

	# Place the new Darwin nearby, with a small random offset
	var spawn_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	new_darwin_instance.global_position = global_position + spawn_offset
	
	#print("Darwin (", name, ") reproduced! New Darwin spawned at ", new_darwin_instance.global_position)
	
	
# --- Debug Drawing (for visualization) ---
#func _draw():
	## Skip drawing in the editor and if essential nodes are missing
	#if Engine.is_editor_hint() or terrain == null: return
	#
	#var bar_width = 40
	#var bar_height = 5
	#
	## Draw Thirst Bar (Blue)
	#var thirst_fill_width = bar_width * (current_thirst / max_thirst)
	#@warning_ignore("integer_division")
	#var thirst_bar_pos = Vector2(-bar_width / 2, -40) # Position above Darwin
	#draw_rect(Rect2(thirst_bar_pos, Vector2(bar_width, bar_height)), Color.GRAY, false) # Background
	#draw_rect(Rect2(thirst_bar_pos, Vector2(thirst_fill_width, bar_height)), Color.BLUE) # Fill
#
	## Draw Hunger Bar (Green)
	#var hunger_fill_width = bar_width * (current_hunger / max_hunger)
	#@warning_ignore("integer_division")
	#var hunger_bar_pos = Vector2(-bar_width / 2, -30) # Slightly below thirst bar
	#draw_rect(Rect2(hunger_bar_pos, Vector2(bar_width, bar_height)), Color.GRAY, false) # Background
	#draw_rect(Rect2(hunger_bar_pos, Vector2(hunger_fill_width, bar_height)), Color.GREEN) # Fill
	#
	## Draw Health Bar (Red)
	#var health_fill_width = bar_width * (current_health / max_health)
	#@warning_ignore("integer_division")
	#var health_bar_pos = Vector2(-bar_width / 2, -20) # Slightly below hunger bar
	#draw_rect(Rect2(health_bar_pos, Vector2(bar_width, bar_height)), Color.GRAY, false) # Background
	#draw_rect(Rect2(health_bar_pos, Vector2(health_fill_width, bar_height)), Color.RED) # Fill
	#
	## Draw current state name text
	## IMPORTANT: You need a default font set in Project Settings > Gui > Theme > Default Font
	## OR load one in _ready() and assign it.
	#var state_display_name = current_state_name.replace("State", "").replace("_", " ").capitalize()
	#@warning_ignore("integer_division")
	#draw_string(ThemeDB.fallback_font, Vector2(-bar_width / 2, -45), state_display_name,0, -1, 16, Color.WHITE)
	#
	## Draw a line to the target tile when seeking resources (visual aid)
	#if target_tile_coords != Vector2i.ZERO and (current_state_name == "SeekingWaterState" or current_state_name == "SeekingFoodState"):
		#var target_world_pos: Vector2 = terrain.map_to_local(target_tile_coords) + (terrain.tile_set.tile_size / 2.0)
		## Convert target world position to a local position relative to the Darwin
		#draw_line(Vector2.ZERO, to_local(target_world_pos), Color.YELLOW, 2)
