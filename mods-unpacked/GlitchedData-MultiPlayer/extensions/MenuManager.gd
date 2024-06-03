extends "res://scripts/MenuManager.gd"

func _input(event):
	var viewingConfig = currentScreen == "mods" and parent_modConfig.has_node("mod config/multiplayer url")
	if (event.is_action_pressed("ui_cancel") and failsafed and not viewingConfig):
		if (currentScreen != "main"): ReturnToLastScreen()
	if (event.is_action_pressed("exit game") and failsafed):
		if (currentScreen != "main"): ReturnToLastScreen()