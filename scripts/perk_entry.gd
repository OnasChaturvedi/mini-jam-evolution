# PerkEntry.gd
extends PanelContainer

signal purchase_requested(perk_resource)

# All the @onready variables from both systems
@onready var name_label: Label = %NameLabel
@onready var description_wrapper: MarginContainer = %DescriptionWrapper
@onready var description_label: Label = %DescriptionLabel
@onready var purchase_button: Button = %PurchaseButton

var perk_data: Perk
var hover_tween: Tween
var full_description_height: float = 0.0

func _ready():
	# Set the label's min height to 0 to prevent the initial layout "explosion".
	description_label.custom_minimum_size.y = 0
	
	# Connect signals for buttons and hovering.
	purchase_button.pressed.connect(_on_purchase_button_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# This function now handles BOTH leveling logic AND animation setup.
func display_perk_info(resource: Perk):
	perk_data = resource
	var current_level = EvolutionManager.get_perk_level(perk_data.perk_id)

	# --- Start of Leveling Display Logic ---
	var full_perk_name = perk_data.perk_name
	if current_level >= 0:
		if current_level == 0:
			full_perk_name += EvolutionManager.get_roman_numeral(1)
		else:
			full_perk_name += EvolutionManager.get_roman_numeral(current_level)
	
	name_label.text = full_perk_name    
	if current_level >= perk_data.get_max_level():
		purchase_button.disabled = true
		purchase_button.text = "Max Level"
		description_label.text = perk_data.descriptions_per_level.back()
	else:
		var next_level_index = current_level
		purchase_button.disabled = false
		purchase_button.text = "Upgrade: %s EP" % perk_data.costs_per_level[next_level_index]
		description_label.text = perk_data.descriptions_per_level[next_level_index]
	# --- End of Leveling Display Logic ---

	# --- Start of Animation Setup Logic ---
	# Now that the text is set, wait a frame for the UI to update.
	await get_tree().process_frame
	
	# Measure the label's true height now that it's populated.
	full_description_height = description_label.size.y
	
	# And start with the wrapper invisible, taking up zero space.
	description_wrapper.visible = false
	# --- End of Animation Setup Logic ---

# --- The Animation Functions (Unchanged from our working version) ---
func _on_mouse_entered():
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	
	description_wrapper.visible = true
	description_wrapper.custom_minimum_size.y = 0
	
	hover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(description_wrapper, "custom_minimum_size:y", full_description_height, 0.2)

func _on_mouse_exited():
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()

	hover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	hover_tween.tween_property(description_wrapper, "custom_minimum_size:y", 0, 0.2)
	hover_tween.finished.connect(func(): description_wrapper.visible = false)
	
# --- The Button Function (Unchanged) ---
func _on_purchase_button_pressed():
	purchase_requested.emit(perk_data)
