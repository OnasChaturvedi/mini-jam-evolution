# world_generator.gd
# Attach this script to a Node2D or a similar node in your Godot scene.
# This script generates a 2D world with biomes based on temperature, humidity, and height noise maps.

extends Node2D

# --- World Generation Parameters ---
@export var world_width: int = 128    # Width of the generated world in tiles
@export var world_height: int = 128   # Height of the generated world in tiles
@export var tile_size: int = 16       # Size of each tile in pixels (e.g., 16x16, 32x32)
									 # THIS MUST MATCH YOUR TILESET'S TILE SIZE!

# --- TileMapLayer Reference ---
# DRAG YOUR 'TerrainTileMap' NODE (WHICH SHOULD BE A TILEMAPLAYER) INTO THIS SLOT IN THE INSPECTOR!
@export var tile_map_node: TileMapLayer

# --- Resource Scene Reference ---
# DRAG YOUR 'Bush.tscn' SCENE INTO THIS SLOT IN THE INSPECTOR!
@export var bush_scene: PackedScene

# --- Height Map Parameter ---
# Defines the normalized height value (0.0 to 1.0) below which a tile is considered water.
# Values closer to 0.0 mean less water, closer to 1.0 mean more water.
@export_range(0.0, 1.0, 0.01) var water_level: float = 0.35 # Default water level threshold

# --- Noise Parameters (for all maps: temperature, humidity, height) ---
# Seed for noise generation to ensure reproducible worlds
@export var seed: int = randi()

# Noise scale determines how 'zoomed in' the noise is. Smaller values mean larger features.
# This directly translates to FastNoiseLite's 'frequency' property.
@export var noise_scale: float = 0.02

# Number of octaves for fractal noise. More octaves add more detail.
@export var octaves: int = 4

# Persistence (or gain) determines how much each octave contributes to the overall shape.
# Higher persistence makes later octaves more impactful (more jagged terrain).
@export var persistence: float = 0.5

# Lacunarity determines the frequency multiplier for each successive octave.
# Higher lacunarity means more fine detail in later octaves.
@export var lacunarity: float = 2.0

# --- Biome Definitions ---
# This dictionary maps biome names to their temperature, humidity,
# corresponding tile coordinates, and specific resource spawn chances.
var biomes: Dictionary = {
	"Ocean": {
		"is_water": true, # Flag to explicitly mark as water based on height
		"tile_coords": Vector2i(0, 0),      # Example: Water tile
		"bush_spawn_chance": 0.0
	},
	"Tundra": {
		"temp_range": Vector2(0.0, 0.3),   # Cold
		"humid_range": Vector2(0.0, 0.5),
		"tile_coords": Vector2i(1, 0),
		"bush_spawn_chance": 0.0
	},
	"Taiga": {
		"temp_range": Vector2(0.0, 0.4),   # Cold to cool
		"humid_range": Vector2(0.5, 1.01),
		"tile_coords": Vector2i(2, 0),
		"bush_spawn_chance": 0.1
	},
	"Grassland": {
		"temp_range": Vector2(0.3, 0.5),   # Temperate
		"humid_range": Vector2(0.3, 0.7),
		"tile_coords": Vector2i(0, 1),
		"bush_spawn_chance": 0.15
	},
	"Forest": {
		"temp_range": Vector2(0.4, 0.8),   # Temperate to warm
		"humid_range": Vector2(0.5, 1.01),
		"tile_coords": Vector2i(1, 1),
		"bush_spawn_chance": 0.25
	},
	"Desert": {
		"temp_range": Vector2(0.7, 1.01),   # Hot
		"humid_range": Vector2(0.0, 0.3),
		"tile_coords": Vector2i(2, 1),
		"bush_spawn_chance": 0.0
	},
	"Jungle": {
		"temp_range": Vector2(0.7, 1.01),   # Hot
		"humid_range": Vector2(0.7, 1.0),
		"tile_coords": Vector2i(0, 2),
		"bush_spawn_chance": 0.35
	},
	"Savanna": { # New biome added
		"temp_range": Vector2(0.6, 1.01), # Warm to hot
		"humid_range": Vector2(0.3, 0.7), # Middle humidity
		"tile_coords": Vector2i(1, 2),    # Example tile coord, adjust as needed in TileSet
		"bush_spawn_chance": 0.08         # Moderate chance in savanna
	},
	"Steppe": { # New biome added
		"temp_range": Vector2(0.3, 0.7), # Cool to warm
		"humid_range": Vector2(0.0, 0.5), # Low humidity
		"tile_coords": Vector2i(2, 2),    # Example tile coord, adjust as needed in TileSet
		"bush_spawn_chance": 0.05         # Low chance in steppe
	},
}

# --- Internal Variables ---
var temperature_map: Array  # 2D array storing normalized temperature values (0.0 to 1.0)
var humidity_map: Array     # 2D array storing normalized humidity values (0.0 to 1.0)
var height_map: Array       # NEW: 2D array storing normalized height values (0.0 to 1.0)
var biome_map: Array        # 2D array storing biome names for each tile
var rng: RandomNumberGenerator # For consistent noise generation based on seed

func _ready():
	# Initialize the random number generator with the provided seed
	rng = RandomNumberGenerator.new()
	rng.seed = seed

	# Generate the world maps in order: Height -> Temperature (influenced by height) -> Humidity
	generate_height_map()
	generate_temperature_map()
	generate_humidity_map()
	determine_biomes()

	# Apply the generated biomes to the TileMapLayer.
	_apply_biomes_to_tilemap()

	print("World generation complete!")
	print("Example: Biome at (5, 5) is: " + biome_map[5][5])


# --- Noise Generation Function ---
# Generates a 2D noise map using FastNoiseLite.
func generate_noise_map(width: int, height: int, scale: float, oct: int, pers: float, lac: float) -> Array:
	var noise_map = []
	for x in range(width):
		noise_map.append([])
		for y in range(height):
			noise_map[x].append(0.0)

	var max_noise_height: float = -INF
	var min_noise_height: float = INF

	var half_width = width / 2.0
	var half_height = height / 2.0

	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_octaves = oct
	noise.fractal_lacunarity = lac
	noise.fractal_gain = pers
	noise.frequency = scale

	for x in range(width):
		for y in range(height):
			var sample_x: float = x - half_width
			var sample_y: float = y - half_height

			var noise_value: float = noise.get_noise_2d(sample_x, sample_y)
			noise_map[x][y] = noise_value

			if noise_value > max_noise_height:
				max_noise_height = noise_value
			elif noise_value < min_noise_height:
				min_noise_height = noise_value

	if max_noise_height != min_noise_height:
		for x in range(width):
			for y in range(height):
				noise_map[x][y] = inverse_lerp(min_noise_height, max_noise_height, noise_map[x][y])
	else:
		for x in range(width):
			for y in range(height):
				noise_map[x][y] = 0.5

	return noise_map

# NEW: Helper function to generate the height map
func generate_height_map():
	height_map = generate_noise_map(world_width, world_height, noise_scale, octaves, persistence, lacunarity)
	print("Height map generated.")

# Helper function to generate the temperature map (now influenced by height)
func generate_temperature_map():
	temperature_map = generate_noise_map(world_width, world_height, noise_scale, octaves, persistence, lacunarity)
	# OPTIONAL: Influence temperature based on height.
	# Higher elevation makes it colder. 'elevation_cold_factor' is a multiplier (0.0 to 1.0)
	var elevation_cold_factor: float = 0.05 # Adjust this value (0.0 means no effect, 1.0 means strong effect)
	for x in range(world_width):
		for y in range(world_height):
			var base_temp = temperature_map[x][y]
			var height_val = height_map[x][y]
			# Reduce temperature based on height (higher height, lower temp)
			temperature_map[x][y] = clamp(base_temp - (height_val * elevation_cold_factor), 0.0, 1.0)
	print("Temperature map generated and influenced by height.")

# Helper function to generate the humidity map
func generate_humidity_map():
	humidity_map = generate_noise_map(world_width, world_height, noise_scale, octaves, persistence, lacunarity)
	# OPTIONAL: Influence humidity based on closeness to water (low height)
	# This is more complex and might involve blurring the height map, so we'll keep it simple for now.
	print("Humidity map generated.")

# --- Biome Determination Function (UPDATED for height and refined biome order) ---
# Iterates through each tile and determines its biome based on height, temperature, and humidity.
func determine_biomes():
	biome_map = []
	for x in range(world_width):
		biome_map.append([])
		for y in range(world_height):
			biome_map[x].append("")

	for x in range(world_width):
		for y in range(world_height):
			var height_val = height_map[x][y]
			var temp_val = temperature_map[x][y]
			var humid_val = humidity_map[x][y]
			var determined_biome: String = "Unknown"

			# 1. First, check for water based on height
			if height_val < water_level:
				determined_biome = "Ocean" # Always ocean if below water_level
			else:
				# 2. If it's land, determine biome based on temperature and humidity.
				# Iterate through all defined land biomes. The order in the dictionary
				# now implies the priority if ranges were to overlap (first match wins).
				# The logic iterates through the biomes dictionary.
				for biome_name in biomes.keys():
					var biome_data = biomes[biome_name]
					# Skip water biomes, as "Ocean" is already handled by height check
					if biome_data.get("is_water", false):
						continue

					var temp_range: Vector2 = biome_data["temp_range"]
					var humid_range: Vector2 = biome_data["humid_range"]

					# Check if current tile's temp and humid values fall within the biome's ranges
					if temp_val >= temp_range.x and temp_val < temp_range.y and \
					   humid_val >= humid_range.x and humid_val < humid_range.y:
						determined_biome = biome_name
						break # Found a biome, no need to check others
			
			# Debugging for unknown biomes
			if determined_biome == "Unknown":
				print("DEBUG: Unknown biome at (" + str(x) + ", " + str(y) +
					  ") - Height: " + str(height_val) + ", Temperature: " + str(temp_val) + ", Humidity: " + str(humid_val))

			biome_map[x][y] = determined_biome
			
	print("Biomes determined.")

# --- TileMapLayer & Resource Integration Function ---
# Populates the TileMapLayer with tiles and places resources based on the determined biomes.
func _apply_biomes_to_tilemap():
	if not is_instance_valid(tile_map_node):
		print("Error: TileMapLayer node is not assigned or is invalid. Make sure to drag your TileMapLayer node into the 'Tile Map Node' slot in the World node's Inspector.")
		return
	if not is_instance_valid(bush_scene):
		print("Error: Bush scene (Bush.tscn) is not assigned. Please drag your Bush.tscn into the 'Bush Scene' slot in the World node's Inspector. No bushes will be spawned.")
		# We will still proceed with tilemap generation if bush_scene is missing

	# Clear any existing tiles on the TileMapLayer before drawing new ones
	tile_map_node.clear()

	# Get the TileSet from the TileMapLayer (it must be assigned in the Inspector!)
	var tile_set = tile_map_node.tile_set
	if not is_instance_valid(tile_set):
		print("Error: TileMapLayer's TileSet is not assigned. Please create and assign a TileSet resource to your TileMapLayer node.")
		return

	# Assuming you have only one TileSet source (your single tilesheet image)
	var source_id = 1 # Corrected: Default source ID for the first added atlas in a TileSet is 0

	# Iterate through every cell in our biome map
	for x in range(world_width):
		for y in range(world_height):
			var biome_name = biome_map[x][y]
			var tile_coords = Vector2i(-1, -1) # Default invalid coords

			# Look up the tile coordinates defined for this biome in our 'biomes' dictionary
			if biomes.has(biome_name):
				tile_coords = biomes[biome_name]["tile_coords"]
			else:
				# If a biome doesn't have defined tile coordinates, print a warning
				print("Warning: Biome '" + biome_name + "' at (" + str(x) + ", " + str(y) + ") has no tile_coords defined in 'biomes' dictionary. This cell will be empty.")

			# If we found valid tile coordinates, set the cell on the TileMapLayer
			if tile_coords != Vector2i(-1, -1):
				tile_map_node.set_cell(Vector2i(x, y), source_id, tile_coords)

			# --- Bush Placement Logic (Uses biome-specific spawn chance) ---
			# Check if the bush_scene is valid and if the biome data has a spawn chance
			if is_instance_valid(bush_scene) and biomes.has(biome_name):
				var current_biome_data = biomes[biome_name]
				# Use .get() with a default value to safely access the spawn chance,
				# ensuring it defaults to 0.0 if not specified for a biome.
				var biome_bush_spawn_chance = current_biome_data.get("bush_spawn_chance", 0.0)

				if rng.randf() < biome_bush_spawn_chance: # Roll the dice with the biome's specific chance
					var bush_instance = bush_scene.instantiate()
					bush_instance.position = Vector2(x * tile_size + tile_size / 2.0, y * tile_size + tile_size / 2.0)
					add_child(bush_instance) # Add bush as a child of the World node
											# You might want to add them to a dedicated "Resources" Node2D for organization.

# --- Godot's `_draw` function is removed as TileMapLayer handles rendering ---
# func _draw():
#    ...
