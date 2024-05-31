extends "res://scripts/UserExit.gd"

var multiplayerManager

func ExitGame():
	multiplayer.multiplayer_peer = null
	multiplayerManager = get_node("/root/MultiplayerManager")
	multiplayerManager.loggedIn = false
	multiplayerManager.inMatch = false
	print("changing scene to: menu")
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
