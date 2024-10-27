extends "res://scripts/ResetManager.gd"

func Reset(hard = true):
	var multiplayerManager = get_node("/root/MultiplayerManager")
	if hard:
		multiplayer.multiplayer_peer = null
		multiplayerManager.loggedIn = false
		multiplayerManager.savedInvite = ""
	multiplayerManager.inMatch = false
	save.ClearSave()
	print("changing scene to: death")
	get_tree().change_scene_to_file("res://scenes/death.tscn")
	fs = true