extends Button

@onready var CREDITS: PackedScene = preload("res://addons/maaacks_credits_scene/examples/scenes/credits/credits.tscn")

func _ready() -> void:
	pressed.connect(_on_ascend_pressed)
	

func _on_ascend_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(CREDITS)
