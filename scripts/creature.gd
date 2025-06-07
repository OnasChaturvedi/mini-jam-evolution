extends CharacterBody2D

@export var speed: float = 100.0 # Adjusted speed for better observation of AI

# --- Core Needs ---
@export var max_thirst: float = 100.0
@export var thirst_depletion_rate: float = 5.0 # How much thirst depletes per second
@export var hydration_rate: float = 20.0 # How much thirst is restored per second when drinking
@export var hydration_threshold: float = 50.0 # Thirst level at which Darwin starts seeking water

@export var max_hunger: float = 100.0
@export var hunger_depletion_rate: float = 3.0 # How much hunger depletes per second
@export var satiation_rate: float = 15.0 # How much hunger is restored per second when eating
@export var hunger_threshold: float = 60.0 # Hunger level at which Darwin starts seeking food

# --- Exploration State Parameters (moved here from state for editor access) ---
@export var exploration_move_duration: float = 0.5 # How long to move in one direction during exploration

@onready var terrain: TileMapLayer = %Terrain # Ensure this %Path is correct in your scene

# --- State Machine Variables ---
var current_state_object: State = null # Holds the actual instantiated state object
var current_state_name: String = "" # Stores the string name of the current state (for debugging)

# Preload all state scripts for efficiency. Adjust paths if your folder structure is different!
const EXPLORATION_STATE = preload("res://scripts/ai_states/exploration_state.gd")
const SEEKING_WATER_STATE =preload("res://scripts/ai_states/seeking_water_state.gd")
const DRINKING_STATE = preload("res://scripts/ai_states/drinking_state.gd")
const SEEKING_FOOD_STATE = preload("res://scripts/ai_states/seeking_food_state.gd")
const EATING_STATE = preload("res://scripts/ai_states/eating_state.gd")
# Add more state preload constants here as you create them!

# --- Darwin Attributes (Current Values) ---
# These are accessed by the state objects via the 'darwin' reference
var current_thirst: float = 0.0
var current_hunger: float = 0.0
var target_tile_coords: Vector2i = Vector2i.ZERO # Stores the coordinates of the tile the Darwin is moving towards


func _ready() -> void:
	if terrain == null:
		print("Tilemap 'Terrain' not found for Darwin: ", name, ". Please ensure it's correctly linked in the editor.")
		set_physics_process(false) # Disable processing if essential nodes are missing
		return
	
	# Initialize needs (e.g., start hungry/thirsty to immediately see behavior)
	current_thirst = max_thirst * max(0.2, randf())
	current_hunger = max_hunger * max(0.2, randf())
	
	# Set the initial state
	change_state("ExplorationState")


func _physics_process(delta: float) -> void:
	# Always update needs regardless of the current state
	_update_needs(delta)
	
	# Delegate the _process logic to the current state object
	if current_state_object != null:
		current_state_object._physics_process(delta)
	
	# Apply the velocity calculated by the current state
	move_and_slide()
	
	# Request a redraw for the debug visualization (thirst/hunger bars, state name)
	queue_redraw()


# This is the central function for changing states
func change_state(new_state_name: String):
	if current_state_name == new_state_name:
		return # Already in this state, no need to change
	
	# First, call the _exit() method of the current state (if one exists)
	if current_state_object != null:
		current_state_object._exit()
	
	# Determine which script to load based on the new_state_name
	var new_state_script = null
	match new_state_name:
		"ExplorationState": new_state_script = EXPLORATION_STATE
		"SeekingWaterState": new_state_script = SEEKING_WATER_STATE
		"DrinkingState": new_state_script = DRINKING_STATE
		"SeekingFoodState": new_state_script = SEEKING_FOOD_STATE
		"EatingState": new_state_script = EATING_STATE
		# Add more cases here for any new states you create
		_:
			print("Error: State '%s' not found or not preloaded!" % new_state_name)
			# You might want to transition to a "DyingState" or "IdleState" here
			return
	
	# Instantiate the new state script and pass a reference to this Darwin
	if new_state_script != null:
		current_state_object = new_state_script.new(self) # 'self' passes this Darwin instance
		current_state_name = new_state_name
		current_state_object._enter() # Call the _enter() method of the new state
	else:
		print("Failed to instantiate state: ", new_state_name)


# This function remains in Darwin.gd because it uses Darwin's own properties
# like 'terrain', 'global_position', and 'tile_set'.
# States will call this method on their 'darwin' reference (e.g., darwin._find_nearest_resource_source(...))
func _find_nearest_resource_source(resource_type: String) -> Vector2i:
	if terrain == null:
		return Vector2i.ZERO

	var current_tile_coords: Vector2i = terrain.local_to_map(global_position)
	var resource_coords: Vector2i = Vector2i.ZERO
	var min_distance_sq: float = INF

	var search_radius: int = 5 # How far to search for resources
	
	for y_offset in range(-search_radius, search_radius + 1):
		for x_offset in range(-search_radius, search_radius + 1):
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


func _update_needs(delta: float):
	# Thirst depletion
	current_thirst = max(0, current_thirst - thirst_depletion_rate * delta)
	# Hunger depletion
	current_hunger = max(0, current_hunger - hunger_depletion_rate * delta)
	
	# --- Implement Death Conditions Here ---
	# For now, just print warnings. In your actual game, you'd trigger a "DyingState"
	# or an actual death event which would log data for "Harvest of Failure".
	if current_thirst <= 0 and current_hunger <= 0:
		print("Darwin (", name, ") is critically thirsty and hungry! (Would die here and log failure)")
		# Example: change_state("DyingState")
	elif current_thirst <= 0:
		print("Darwin (", name, ") is critically thirsty! (Would die here)")
	elif current_hunger <= 0:
		print("Darwin (", name, ") is critically hungry! (Would die here)")


# --- Debug Drawing (for visualization during development) ---
func _draw():
	# Skip drawing in the editor and if essential nodes are missing
	if Engine.is_editor_hint() or terrain == null: return
	
	var bar_width = 40
	var bar_height = 5
	
	# Draw Thirst Bar (Blue)
	var thirst_fill_width = bar_width * (current_thirst / max_thirst)
	var thirst_bar_pos = Vector2(-bar_width / 2, -30) # Position above Darwin
	draw_rect(Rect2(thirst_bar_pos, Vector2(bar_width, bar_height)), Color.GRAY, false) # Background
	draw_rect(Rect2(thirst_bar_pos, Vector2(thirst_fill_width, bar_height)), Color.BLUE) # Fill

	# Draw Hunger Bar (Green)
	var hunger_fill_width = bar_width * (current_hunger / max_hunger)
	var hunger_bar_pos = Vector2(-bar_width / 2, -20) # Slightly below thirst bar
	draw_rect(Rect2(hunger_bar_pos, Vector2(bar_width, bar_height)), Color.GRAY, false) # Background
	draw_rect(Rect2(hunger_bar_pos, Vector2(hunger_fill_width, bar_height)), Color.GREEN) # Fill

	# Draw current state name text
	# IMPORTANT: You need a default font set in Project Settings > Gui > Theme > Default Font
	# OR load one in _ready() and assign it.
	var state_display_name = current_state_name.replace("State", "").replace("_", " ").capitalize()
	draw_string(ThemeDB.fallback_font, Vector2(-bar_width / 2, -45), state_display_name,0, -1, 16, Color.WHITE)
	
	# Optional: Draw a line to the target tile when seeking resources (visual aid)
	if target_tile_coords != Vector2i.ZERO and (current_state_name == "SeekingWaterState" or current_state_name == "SeekingFoodState"):
		var target_world_pos: Vector2 = terrain.map_to_local(target_tile_coords) + (terrain.tile_set.tile_size / 2.0)
		# Convert target world position to a local position relative to the Darwin
		draw_line(Vector2.ZERO, to_local(target_world_pos), Color.YELLOW, 2)
