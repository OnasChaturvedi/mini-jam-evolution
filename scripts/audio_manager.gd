extends AudioStreamPlayer

const STARTSOUND = preload("res://assets/startsound.wav")
const BUYSOUND = preload("res://assets/buysound.wav")
const MENUOPEN = preload("res://assets/menuopen.wav")
const BUYFAIL = preload("res://assets/buyfail.wav")
const DEATH_SOUND = preload("res://assets/death_sound.mp3")

func play_start_sound():
	volume_db = 0
	stream = STARTSOUND
	play()

func play_menu_sound():
	volume_db = -10
	stream = MENUOPEN
	play()
	
func play_buy_sound():
	volume_db = 0
	stream = BUYSOUND
	play()

func play_fail_sound():
	volume_db = -8
	stream = BUYFAIL
	play()

func play_die_sound():
	volume_db = -10
	stream = DEATH_SOUND
	play()
