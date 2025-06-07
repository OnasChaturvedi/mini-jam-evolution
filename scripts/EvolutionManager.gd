# EvolutionManager.gd
extends Node

var evolution_points: int = 0

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
