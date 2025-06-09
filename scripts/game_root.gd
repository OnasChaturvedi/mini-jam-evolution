# In your main world script (e.g., World.gd)
extends Node2D

const DeathNotification = preload("res://scenes/death_notification.tscn")

@onready var creature_container: Node2D = $CreatureContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var reload_delay_timer: Timer = $ReloadDelayTimer

@export var initial_creature_count: int = 10
@export var initial_enemy_count: int = 5
@export var creature_scene: PackedScene 	
@export var enemy_scene: PackedScene
@onready var evolution_menu_instance: PanelContainer = $CanvasLayer/EvolutionMenu

func _ready():
	spawn_initial_creatures()
	# Connect to the death signal from the global manager.
	EvolutionManager.creature_died.connect(on_creature_died)
	reload_delay_timer.timeout.connect(reload_game_scene)

func on_creature_died(cause: String, position: Vector2):
	# Create a new instance of the notification.
	var notification_instance = DeathNotification.instantiate()
	
	# The notification needs to be on a CanvasLayer to display correctly.
	# We can create one just for notifications.
	var notification_layer = CanvasLayer.new()
	add_child(notification_layer)
	notification_layer.add_child(notification_instance)

	# Build the message text.
	var death_message = null
	match cause:
		"thirst":
			death_message = "A Darwin couldn't get to water"
		"hunger":
			death_message = "A Darwin starved to death"
		"age":
			death_message = "A Darwin lived out it's life"
		"murder":
			death_message = "A Darwin was mauled to death"
		"freezing":
			death_message = "A Darwin froze to death"
		"overheating":
			death_message = "A Darwin melted"
	
	# Trigger the animation. The script inside the notification handles the rest.
	notification_instance.show_message(death_message)
	
	if get_tree().get_nodes_in_group("creatures").size() <= 1:
		reload_delay_timer.start()


func reload_game_scene() -> void:
	get_tree().reload_current_scene()
	

func spawn_initial_creatures():
	for i in range(initial_creature_count):
		spawn_creature_in_camera_viewport(creature_scene)
	for i in range(initial_enemy_count):
		spawn_creature_in_camera_viewport(enemy_scene)


func spawn_creature_in_camera_viewport(spawnable_scene: PackedScene):
	if creature_scene == null or creature_container == null:
		return

	var viewport_rect: Rect2 = get_viewport_rect()

	var random_x = randf_range(viewport_rect.position.x, viewport_rect.position.x + viewport_rect.size.x)
	var random_y = randf_range(viewport_rect.position.y, viewport_rect.position.y + viewport_rect.size.y)
	
	var spawn_position = Vector2(random_x, random_y)

	var new_creature_instance = spawnable_scene.instantiate()
	
	new_creature_instance.global_position = spawn_position
	if new_creature_instance is Darwin:
		creature_container.add_child(new_creature_instance)
	elif new_creature_instance is Enemy:
		enemy_container.add_child(new_creature_instance)
	#print("Spawned creature at: ", spawn_position)
	
	
func _unhandled_input(event: InputEvent):
	# Check if the "ui_cancel" action (Escape key) was just pressed.
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause_game"):
		# If the game is already paused, hide the menu.
		if get_tree().paused:
			evolution_menu_instance.hide_menu()
		# Otherwise, show the menu.
		else:
			evolution_menu_instance.show_menu()
			AudioManager.play_menu_sound()
			
