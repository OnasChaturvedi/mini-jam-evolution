# In your main world script (e.g., World.gd)
extends Node2D

const DeathNotification = preload("res://scenes/death_notification.tscn")
@onready var evolution_menu_instance: PanelContainer = $CanvasLayer/EvolutionMenu

func _ready():
	# Connect to the death signal from the global manager.
	EvolutionManager.creature_died.connect(on_creature_died)
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
func _unhandled_input(event: InputEvent):
	# Check if the "ui_cancel" action (Escape key) was just pressed.
	if Input.is_action_just_pressed("ui_cancel"):
		# If the game is already paused, hide the menu.
		if get_tree().paused:
			evolution_menu_instance.hide_menu()
		# Otherwise, show the menu.
		else:
			evolution_menu_instance.show_menu()
