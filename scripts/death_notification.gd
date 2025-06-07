# DeathNotification.gd
extends Label

func show_message(message: String):
	text = message
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	modulate.a = 0.0 # Start invisible
	
	var screen_size = get_viewport_rect().size
	# We subtract 30 from the start position because the animation will move it up by 30
	global_position = Vector2(screen_size.x / 2, screen_size.y - 70) 
	
	var tween = create_tween()

	# --- Animation Sequence ---
	
	# Step 1: FADE-IN BLOCK.
	# Animate opacity and position in parallel. This block takes 0.5 seconds.
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "position:y", global_position.y - 30, 0.5)
	
	# Step 2: LINGER BLOCK.
	# The .chain() command forces the tween to wait for Step 1 to finish.
	# Then, it will run this interval (the pause).
	tween.chain().tween_interval(1.0) # This will now be a full 1-second pause.
	
	# Step 3: FADE-OUT BLOCK.
	# .chain() forces the tween to wait for the interval in Step 2 to finish.
	# Then, it will fade out and move up in parallel.
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "position:y", global_position.y - 60, 0.5)
	
	# Step 4: CLEANUP.
	# After the entire chained sequence is done, remove the node.
	tween.finished.connect(queue_free)
