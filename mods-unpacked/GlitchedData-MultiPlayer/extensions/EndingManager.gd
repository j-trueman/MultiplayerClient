extends "res://scripts/EndingManager.gd"

var multiplayerManager

func _ready():
	multiplayerManager = get_tree().get_root().get_node("MultiplayerManager")

func ExitGame():
	animator_viewblocker.play("fade in")
	cntrl_endingmusic.FadeOut()
	cntrl_ambience.fadeDuration = 3
	cntrl_ambience.FadeOut()
	isActive = false
	await get_tree().create_timer(4, false).timeout
	multiplayerManager.inMatch = false
	roundManager.death.MainDeathRoutine()