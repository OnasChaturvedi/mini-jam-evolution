class_name State extends RefCounted

var darwin: CharacterBody2D = null

func _init(darwin_ref: CharacterBody2D):
	darwin = darwin_ref

# Called once when entering this state
func _enter():
	pass

# Called every physics frame while in this state
func _physics_process(delta: float):
	pass

# Called once when exiting this state
func _exit():
	pass

# States can request a transition in the Darwin's main script
func change_state(new_state_name: String):
	if darwin and "change_state" in darwin:
		darwin.change_state(new_state_name)
