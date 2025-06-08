extends CanvasLayer
@onready var number_label: Label = %NumberLabel

func _ready():
	# Connect to the global manager's signal.
	EvolutionManager.evolution_points_changed.connect(on_points_changed)
	# Set the initial value.
	number_label.text = str(EvolutionManager.evolution_points)

func on_points_changed(new_points: int):
	number_label.text = str(new_points)
