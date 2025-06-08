# EvolutionMenu.gd
extends PanelContainer
const PerkEntryScene = preload("res://scenes/perk_entry.tscn")
@onready var points_display_label: Label = %PointDisplayLabel
@onready var resume_button: Button = %ResumeButton
@export var perks_to_display: Array[Perk]
@onready var perks_list: VBoxContainer = %PerksList

func _ready():
	# Connect the resume button's pressed signal to the hide_menu function.
	resume_button.pressed.connect(hide_menu)
	
	# Connect to the EvolutionManager to update the points display.
	EvolutionManager.evolution_points_changed.connect(update_points_display)
	populate_perks_list()	
	# Hide the menu when the game starts.
	hide_menu()
func populate_perks_list():
	for perk_resource in perks_to_display:
		# Create a new instance of our template scene.
		var perk_entry = PerkEntryScene.instantiate()
		perks_list.add_child(perk_entry)
		
		# Set its data and connect its signal.
		perk_entry.display_perk_info(perk_resource)
		perk_entry.purchase_requested.connect(_on_perk_purchase_requested)
			   # If we already own this perk, disable its button.
		if EvolutionManager.has_perk(perk_resource.perk_id):
			perk_entry.disable_purchase()
# Function to show the menu and pause the game.
func _on_perk_purchase_requested(perk_to_buy: Perk):
	var current_level = EvolutionManager.get_perk_level(perk_to_buy.perk_id)
	if current_level < perk_to_buy.get_max_level():
		var cost_of_next_level = perk_to_buy.costs_per_level[current_level]
		if EvolutionManager.spend_points(cost_of_next_level):
			# If purchase is successful, upgrade the perk
			EvolutionManager.upgrade_perk(perk_to_buy.perk_id)
			print("Successfully upgraded %s" % perk_to_buy.perk_name)
			
			# Find the UI entry for this perk and tell it to refresh its display
			for child in perks_list.get_children():
				if child.perk_data.perk_id == perk_to_buy.perk_id:
					child.display_perk_info(perk_to_buy)
					break
		else:
			print("Not enough EP to upgrade %s" % perk_to_buy.perk_name)
func show_menu():
	# Update the points display every time the menu is shown.
	update_points_display(EvolutionManager.evolution_points)
	visible = true
	get_tree().paused = true

# Function to hide the menu and unpause the game.
func hide_menu():
	visible = false
	get_tree().paused = false

# Updates the text of the points label.
func update_points_display(new_points: int):
	points_display_label.text = "EP: %s" % new_points
# In EvolutionManager.gd

# A helper to convert a number to a Roman numeral string.
# We use a dictionary for clarity.
