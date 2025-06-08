# PerkResource.gd
extends Resource
class_name Perk

@export var perk_id: String # A unique ID, e.g., "faster_creatures"
@export var perk_name: String # The display name, e.g., "Increased Metabolism"

# --- NEW: Use arrays for level-based data ---
# The cost for each level (level 1, level 2, etc.)
@export var costs_per_level: Array[int]
# The description for each level. You can use %s as a placeholder.
@export var descriptions_per_level: Array[String]
# The bonus value for each level (e.g., 0.15 for 15% speed).
@export var bonuses_per_level: Array[float]

# A helper function to get the max level.
func get_max_level() -> int:
	return costs_per_level.size()
