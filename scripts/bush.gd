extends Area2D
class_name BerryBush

@export var feeds_count: int = 1


func feed() -> void:
	feeds_count -= 1
	if feeds_count <= 0:
		call_deferred("queue_free")

func has_berries() -> bool:
	return feeds_count > 0
