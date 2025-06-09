extends Node2D

@onready var game_scene = preload("res://scenes/main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		AudioManager.play_start_sound()
		get_tree().change_scene_to_packed(game_scene)
