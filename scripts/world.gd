extends Node2D
# --- World Generation Parameters ---
@export var world_width: int = 128    # Width of the generated world in tiles
@export var world_height: int = 128   # Height of the generated world in tiles
@export var tile_size: int = 16       # Size of each tile in pixels (e.g., 16x16, 32x32)
# --- TileMapLayer Reference ---
@export var tile_map_node: TileMapLayer
# --- Noise Parameters (for both temperature and humidity) ---
@export var seed: int = randi()
@export var noise_scale: float = 0.02
@export var octaves: int = 4
@export var persistence: float = 0.5
@export var lacunarity: float = 2.0
# --- Biome Definitions ---
var biomes: Dictionary = {
	"Ocean": {
		"temp_range": Vector2(0.0, 0.4), #cold
		"humid_range": Vector2(0.0, 1.0), #does not matter
		"tile_coords": Vector2i(0, 0)
	},
	"Tundra": {
		"temp_range": Vector2(0.4, 0.6), #cool
		"humid_range": Vector2(0.0, 0.5), #low-mid 
		"tile_coords": Vector2i(1, 0)
	},
	"Taiga": {
		"temp_range": Vector2(0.4, 0.6), #cool
		"humid_range": Vector2(0.5, 1.0), #mid-high 
		"tile_coords": Vector2i(2, 0)
	},
	"Grassland": {
		"temp_range": Vector2(0.6, 0.8), #warm
		"humid_range": Vector2(0.3, 0.7), #middle 
		"tile_coords": Vector2i(0, 1)
	},
	"Forest": {
		"temp_range": Vector2(0.6, 0.8), #warm
		"humid_range": Vector2(0.7, 1.0), #high
		"tile_coords": Vector2i(1, 1)
	},
	"Desert": {
		"temp_range": Vector2(0.8, 1.0), #hot
		"humid_range": Vector2(0.0, 0.3), #low
		"tile_coords": Vector2i(2, 1)
	},
	"Jungle": {
		"temp_range": Vector2(0.8, 1.0), #hot
		"humid_range": Vector2(0.7, 1.0), #high
		"tile_coords": Vector2i(0, 2)
	},
	# Add more biomes here as needed
}

# --- Internal Variables ---
var temperature_map: Array  # 2D array storing temperature values (0.0 to 1.0)
var humidity_map: Array     # 2D array storing humidity values (0.0 to 1.0)
var biome_map: Array        # 2D array storing biome names for each tile
var rng: RandomNumberGenerator # For consistent noise generation based on seed

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	generate_temperature_map()
	generate_humidity_map()
	determine_biomes()
	_apply_biomes_to_tilemap()
	print("World generation complete!")
	print("Example: Biome at (5, 5) is: " + biome_map[5][5])
# --- Noise Generation Function ---
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
func generate_temperature_map():
	temperature_map = generate_noise_map(world_width, world_height, noise_scale, octaves, persistence, lacunarity)
	print("Temperature map generated.")
func generate_humidity_map():
	humidity_map = generate_noise_map(world_width, world_height, noise_scale, octaves, persistence, lacunarity)
	print("Humidity map generated.")

# --- Biome Determination Function ---
func determine_biomes():
	biome_map = []
	for x in range(world_width):
		biome_map.append([])
		for y in range(world_height):
			biome_map[x].append("")

	for x in range(world_width):
		for y in range(world_height):
			var temp_val = temperature_map[x][y]
			var humid_val = humidity_map[x][y]
			var determined_biome: String = "Unknown" # Default biome if no match
			for biome_name in biomes.keys():
				var biome_data = biomes[biome_name]
				var temp_range: Vector2 = biome_data["temp_range"]
				var humid_range: Vector2 = biome_data["humid_range"]
				if temp_val >= temp_range.x and temp_val < temp_range.y and \
				   humid_val >= humid_range.x and humid_val < humid_range.y:
					determined_biome = biome_name
					break

			biome_map[x][y] = determined_biome

	print("Biomes determined.")
# --- TileMapLayer Integration Function ---
func _apply_biomes_to_tilemap():
	if not is_instance_valid(tile_map_node):
		print("Error: TileMapLayer node is not assigned or is invalid. Make sure to drag your TileMapLayer node into the 'Tile Map Node' slot in the World node's Inspector.")
		return
	tile_map_node.clear()
	var tile_set = tile_map_node.tile_set
	if not is_instance_valid(tile_set):
		print("Error: TileMapLayer's TileSet is not assigned. Please create and assign a TileSet resource to your TileMapLayer node.")
		return
	var source_id = 1 
	for x in range(world_width):
		for y in range(world_height):
			var biome_name = biome_map[x][y]
			var tile_coords = Vector2i(-1, -1)
			if biomes.has(biome_name):
				tile_coords = biomes[biome_name]["tile_coords"]
			else:
				print("Warning: Biome '" + biome_name + "' at (" + str(x) + ", " + str(y) + ") has no tile_coords defined in 'biomes' dictionary. This cell will be empty.")
			if tile_coords != Vector2i(-1, -1):
				tile_map_node.set_cell(Vector2i(x, y), source_id, tile_coords)
