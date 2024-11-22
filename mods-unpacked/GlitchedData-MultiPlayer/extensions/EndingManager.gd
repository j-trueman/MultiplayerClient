extends "res://scripts/EndingManager.gd"

var multiplayerManager
var resetManager

func _ready():
	multiplayerManager = get_tree().get_root().get_node("MultiplayerManager")
	resetManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/reset manager")

func ExitGame():
	animator_viewblocker.play("fade in")
	cntrl_endingmusic.FadeOut()
	cntrl_ambience.fadeDuration = 3
	cntrl_ambience.FadeOut()
	isActive = false
	await get_tree().create_timer(4, false).timeout
	resetManager.Reset()

func FinalScore():
	endless_overwriting = true
	endless_score = 70000
	super()
	