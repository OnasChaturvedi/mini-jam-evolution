# world_generator.gd
# Attach this script to a Node2D or a similar node in your Godot scene.
# This script generates a 2D world with biomes based on temperature and humidity noise maps.

extends Node2D

# --- World Generation Parameters ---
@export var world_width: int = 128    # Width of the generated world in tiles
@export var world_height: int = 128   # Height of the generated world in tiles
@export var tile_size: int = 16       # Size of each tile in pixels (e.g., 16x16, 32x32)
									 # THIS MUST MATCH YOUR TILESET'S TILE SIZE!

# --- TileMap Reference ---
# DRAG YOUR 'TerrainTileMap' NODE INTO THIS SLOT IN THE INSPECTOR!
@export var tile_map_node: TileMap

# --- Noise Parameters (for both temperature and humidity) ---
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
# This dictionary maps biome names to their temperature and humidity ranges,
# and crucially, their corresponding tile coordinates in your TileSet's atlas.
# The values for temp/humidity are normalized (0.0 to 1.0).
# You can customize these ranges and add more biomes.
var biomes: Dictionary = {
	"Ocean": {
		"temp_range": Vector2(0.0, 0.4),
		"humid_range": Vector2(0.0, 1.0),
		"tile_coords": Vector2i(0, 0)      # <--- IMPORTANT: UPDATE THESE TO YOUR TILESET'S ATLAS COORDS!
	},
	"Tundra": {
		"temp_range": Vector2(0.4, 0.6),
		"humid_range": Vector2(0.0, 0.5),
		"tile_coords": Vector2i(1, 0)      # Example: If tundra tile is at (1,0) in your tilesheet
	},
	"Taiga": {
		"temp_range": Vector2(0.4, 0.6),
		"humid_range": Vector2(0.5, 1.0),
		"tile_coords": Vector2i(2, 0)      # Example: If taiga tile is at (2,0) in your tilesheet
	},
	"Grassland": {
		"temp_range": Vector2(0.6, 0.8),
		"humid_range": Vector2(0.3, 0.7),
		"tile_coords": Vector2i(0, 1)      # Example: If grassland tile is at (0,1) in your tilesheet
	},
	"Forest": {
		"temp_range": Vector2(0.6, 0.8),
		"humid_range": Vector2(0.7, 1.0),
		"tile_coords": Vector2i(1, 1)      # Example: If forest tile is at (1,1) in your tilesheet
	},
	"Desert": {
		"temp_range": Vector2(0.8, 1.0),
		"humid_range": Vector2(0.0, 0.3),
		"tile_coords": Vector2i(2, 1)      # Example: If desert tile is at (2,1) in your tilesheet
	},
	"Jungle": {
		"temp_range": Vector2(0.8, 1.0),
		"humid_range": Vector2(0.7, 1.0),
		"tile_coords": Vector2i(0, 2)      # Example: If jungle tile is at (0,2) in your tilesheet
	},
	# Add more biomes here as needed
}

# --- Internal Variables ---
var temperature_map: Array  # 2D array storing temperature values (0.0 to 1.0)
var humidity_map: Array     # 2D array storing humidity values (0.0 to 1.0)
var biome_map: Array        # 2D array storing biome names for each tile
var rng: RandomNumberGenerator # For consistent noise generation based on seed

func _ready():
	# Initialize the random number generator with the provided seed
	rng = RandomNumberGenerator.new()
	rng.seed = seed

	# Generate the world maps
	generate_temperature_map()
	generate_humidity_map()
	determine_biomes()

	# Apply the generated biomes to the TileMap.
	# No need for queue_redraw() anymore as TileMap handles its own rendering.
	_apply_biomes_to_tilemap()

	print("World generation complete!")
	print("Example: Biome at (5, 5) is: " + biome_map[5][5])


# --- Noise Generation Function ---
# Generates a 2D noise map using FastNoiseLite.
# This function creates the underlying 'terrain' for temperature and humidity.
func generate_noise_map(width: int, height: int, scale: float, oct: int, pers: float, lac: float) -> Array:
	var noise_map = []
	# Initialize the 2D array
	for x in range(width):
		noise_map.append([])
		for y in range(height):
			noise_map[x].append(0.0)

	# Calculate min/max noise height to normalize later
	var max_noise_height: float = -INF
	var min_noise_height: float = INF

	var half_width = width / 2.0
	var half_height = height / 2.0

	# Initialize FastNoiseLite once per map generation
	var noise = FastNoiseLite.new()
	noise.seed = rng.randi() # Use RNG's seed for the FastNoiseLite instance
	noise.noise_type = FastNoiseLite.TYPE_PERLIN # Or TYPE_SIMPLEX for a different look

	# Set fractal noise properties directly. fractal_enabled is implicitly true when these are set.
	noise.fractal_octaves = oct
	noise.fractal_lacunarity = lac
	noise.fractal_gain = pers
	noise.frequency = scale # The 'scale' parameter directly controls FastNoiseLite's frequency

	# Iterate through each pixel to generate noise
	for x in range(width):
		for y in range(height):
			# Calculate sample coordinates, potentially offsetting for centering
			var sample_x: float = x - half_width
			var sample_y: float = y - half_height

			# Get the noise value. FastNoiseLite handles octaves and fractal settings internally.
			var noise_value: float = noise.get_noise_2d(sample_x, sample_y)
			noise_map[x][y] = noise_value

			# Update min/max noise heights
			if noise_value > max_noise_height:
				max_noise_height = noise_value
			elif noise_value < min_noise_height:
				min_noise_height = noise_value

	# Normalize the noise map values to be between 0.0 and 1.0
	# Only normalize if there's a range to normalize over to avoid division by zero
	if max_noise_height != min_noise_height:
		for x in range(width):
			for y in range(height):
				noise_map[x][y] = inverse_lerp(min_noise_height, max_noise_height, noise_map[x][y])
	else:
		# If all noise values are identical (e.g., in very rare edge cases), set them to a default
		for x in range(width):
			for y in range(height):
				noise_map[x][y] = 0.5 # Mid-range as a fallback

	return noise_map

# Helper function to generate the temperature map
func generate_temperature_map():
	# Use global noise parameters for temperature (you can have separate ones if needed)
	temperature_map = generate_noise_map(world_width, world_height, noise_scale, octaves, persistence, lacunarity)
	print("Temperature map generated.")

# Helper function to generate the humidity map
func generate_humidity_map():
	# Use global noise parameters for humidity (you can have separate ones if needed)
	humidity_map = generate_noise_map(world_width, world_height, noise_scale, octaves, persistence, lacunarity)
	print("Humidity map generated.")

# --- Biome Determination Function ---
# Iterates through each tile and determines its biome based on temperature and humidity.
func determine_biomes():
	biome_map = []
	# Initialize the 2D array for biome names
	for x in range(world_width):
		biome_map.append([])
		for y in range(world_height): # Corrected: Changed 'height' to 'world_height'
			biome_map[x].append("") # Initialize with an empty string

	for x in range(world_width):
		for y in range(world_height): # Corrected: Changed 'height' to 'world_height'
			var temp_val = temperature_map[x][y]
			var humid_val = humidity_map[x][y]
			var determined_biome: String = "Unknown" # Default biome if no match

			# Iterate through defined biomes to find a match
			for biome_name in biomes.keys():
				var biome_data = biomes[biome_name]
				var temp_range: Vector2 = biome_data["temp_range"]
				var humid_range: Vector2 = biome_data["humid_range"]

				# Check if current tile's temp and humid values fall within the biome's ranges
				if temp_val >= temp_range.x and temp_val < temp_range.y and \
				   humid_val >= humid_range.x and humid_val < humid_range.y:
					determined_biome = biome_name
					break # Found a biome, no need to check others

			biome_map[x][y] = determined_biome

	print("Biomes determined.")

# --- TileMap Integration Function ---
# Populates the TileMap with tiles based on the determined biomes.
func _apply_biomes_to_tilemap():
	if not is_instance_valid(tile_map_node):
		print("Error: TileMap node is not assigned or is invalid. Make sure to drag your TileMap node into the 'Tile Map Node' slot in the World node's Inspector.")
		return

	# Clear any existing tiles on the TileMap before drawing new ones
	tile_map_node.clear()

	# Get the TileSet from the TileMap (it must be assigned in the Inspector!)
	var tile_set = tile_map_node.tile_set
	if not is_instance_valid(tile_set):
		print("Error: TileMap's TileSet is not assigned. Please create and assign a TileSet resource to your TileMap node.")
		return

	# Assuming you have only one TileSet source (your single tilesheet image)
	var source_id = 0 # Default source ID for the first added atlas in a TileSet

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

			# If we found valid tile coordinates, set the cell on the TileMap
			if tile_coords != Vector2i(-1, -1):
				# Layer 0 is typically the base layer for tiles. Adjust if you have multiple layers.
				var layer = 0
				tile_map_node.set_cell(layer, Vector2i(x, y), source_id, tile_coords)
# --- Godot's `_draw` function is removed as TileMap handles rendering ---
# func _draw():
#    ...
