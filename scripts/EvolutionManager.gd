extends Node

signal perk_unlocked(perk_id)

const ROMAN_NUMERALS = {
	1: " I",
	2: " II",
	3: " III",
	4: " IV",
	5: " V", 
	6: " VI",
	7: " VII",
	8: " VIII",
	9: " IX",
	10: " X",
	11: " XI",
	12: " XII",
	13: " XIII",
	14: " XIV",
	15: " XV",
	16: " XVI",
	17: " XVII",
	18: " XVIII",
	19: " XIX"
}

var evolution_points: int = 0
var unlocked_perks: Dictionary = {}

signal evolution_points_changed(new_points)
signal creature_died(cause_of_death, position)

# This function now takes the amount of points to add.
func add_points(amount: int):
	evolution_points += amount
	evolution_points_changed.emit(evolution_points)
	
	
# This function now accepts a 'points_value' argument.
func report_death(cause: String, position: Vector2, points_value: int):
	creature_died.emit(cause, position)
	# Add the points that were passed in.
	add_points(points_value)
	
	
func spend_points(amount: int) -> bool:
	if evolution_points >= amount:
		evolution_points -= amount
		evolution_points_changed.emit(evolution_points)
		return true
	else:
		return false
		
		
func get_perk_level(perk_id: String) -> int:
	if has_perk(perk_id):
		return unlocked_perks[perk_id].level
	return 0 # Return 0 if the perk is not owned
	
	
func has_perk(perk_id: String) -> bool:
	return unlocked_perks.has(perk_id)
	
	
func upgrade_perk(perk: Perk):
	if not has_perk(perk.perk_id):
		unlocked_perks[perk.perk_id].level = 1 # First purchase is level 1
	else:
		unlocked_perks[perk.perk_id].level += 1 # Subsequent purchases increase the level
	unlocked_perks[perk.perk_id].bonus = perk.bonuses_per_level[get_perk_level(perk.perk_id) - 1]
	perk_unlocked.emit(perk.perk_id) # We can still emit this signal
	print(unlocked_perks)
	

func get_roman_numeral(level: int) -> String:
	if ROMAN_NUMERALS.has(level):
		return ROMAN_NUMERALS[level]
	return " " + str(level) # Fallback for higher levels
