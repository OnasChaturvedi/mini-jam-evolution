# In your main world script (e.g., World.gd)
extends Node2D

const DeathNotification = preload("res://scenes/death_notification.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var creature_container: Node2D = $CreatureContainer
@onready var reload_delay_timer: Timer = $ReloadDelayTimer

@export var initial_creature_count: int = 10
@export var creature_scene: PackedScene 	
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
	if(cause == "thirst"):
		death_message = "A Darwinian couldn't get to water"
	elif(cause == "hunger"):
		death_message = "A Darwinian starved to death"
	elif(cause == "age"):
		death_message = "A Darwinian lived out it's life"
	
	# Trigger the animation. The script inside the notification handles the rest.
	notification_instance.show_message(death_message)
	
	if get_tree().get_nodes_in_group("creatures").size() <= 1:
		reload_delay_timer.start()


func reload_game_scene() -> void:
	get_tree().reload_current_scene()
	

func spawn_initial_creatures():
	for i in range(initial_creature_count):
		spawn_creature_in_camera_viewport()


func spawn_creature_in_camera_viewport():
	if creature_scene == null or camera == null or creature_container == null:
		return

	var viewport_rect: Rect2 = camera.get_viewport_rect()

	var viewport_top_left_global = camera.global_position - viewport_rect.size / 2.0
	var viewport_bottom_right_global = camera.global_position + viewport_rect.size / 2.0

	var random_x = randf_range(viewport_top_left_global.x, viewport_bottom_right_global.x)
	var random_y = randf_range(viewport_top_left_global.y, viewport_bottom_right_global.y)
	
	var spawn_position = Vector2(random_x, random_y)

	var new_creature_instance = creature_scene.instantiate()
	
	new_creature_instance.global_position = spawn_position
	creature_container.add_child(new_creature_instance)
	#print("Spawned creature at: ", spawn_position)
func _unhandled_input(event: InputEvent):
	# Check if the "ui_cancel" action (Escape key) was just pressed.
	if Input.is_action_just_pressed("ui_cancel"):
		# If the game is already paused, hide the menu.
		if get_tree().paused:
			evolution_menu_instance.hide_menu()
		# Otherwise, show the menu.
		else:
			evolution_menu_instance.show_menu()
