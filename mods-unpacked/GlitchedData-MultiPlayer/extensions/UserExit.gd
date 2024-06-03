extends "res://scripts/UserExit.gd"

func ExitGame():
	multiplayer.multiplayer_peer = null
	var multiplayerManager = get_node("/root/MultiplayerManager")
	multiplayerManager.loggedIn = false
	multiplayerManager.inMatch = false
	print("changing scene to: menu")
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
