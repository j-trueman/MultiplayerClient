extends "res://scripts/UserExit.gd"

var multiplayerManager

func _ready():
	await get_tree().create_timer(.5, false).timeout
	exitAllowed = true
	var multiplayerManager = get_tree().get_root().get_node("MultiplayerManager")

func ExitGame():
	multiplayer.multiplayer_peer = null
	multiplayerManager.loggedIn = false
	multiplayerManager.inMatch = false
	print("changing scene to: menu")
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(delta):
	if exitAllowed:
		if (Input.is_action_just_pressed("exit game") and multiplayerManager.inviteMenu.chatTimer):
			ShowUI()
		if Input.is_action_pressed("exit game"):
			total += delta
	if Input.is_action_just_released("exit game"):
		total = 0
	CheckExit()

