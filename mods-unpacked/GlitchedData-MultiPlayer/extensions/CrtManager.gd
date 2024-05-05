extends "res://scripts/CrtManager.gd"

@export var screenparent_multiplayer : Node3D
var multiplayerManager
var multiplayerMenuManager
var playerList
var playerListPage = 0
var maxListPages
var inviteeID

func Bootup():
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	multiplayerMenuManager = screenparent_multiplayer.get_node("multiplayermenu")
	has_exited = false
	board.lock.material_override.albedo_color = Color(1, 1, 1, 0)
	screenparent_multiplayer.visible = true
#	HighlightOption("lobbies", 0)
#	await MultiplayerStartup()
	multiplayerMenuManager.username_input.viewingCRT = true
	HighlightOption("login", 0)
	window_index = 0
	for icon in iconbranches: icon.CheckState(window_index)
	anim_iconfade.play("fade in")
	await get_tree().create_timer(.5, false).timeout
	intro.EnabledInteractionCRT()
	exit.exitAllowed = false
	viewing = true

func MultiplayerStartup():
	HighlightOption("players", 0)
	window_index = 2
	multiplayerMenuManager.options_index = 0
	multiplayerMenuManager.screenparent_login.visible = false
	multiplayerMenuManager.screenparent_players.visible = true
	multiplayerMenuManager.screenparent_invite.visible = false
	print(multiplayer.multiplayer_peer)
	multiplayerManager.requestPlayerList.rpc()
	playerList = await multiplayerManager.player_list
	var numOfPlayers = len(playerList)
	maxListPages = (numOfPlayers/7) 
	DrawNewPage()

func DrawNewPage():
	multiplayerMenuManager.options_players_visible = 0
	for label in multiplayerMenuManager.options_players:
		label.visible = false
		label.text = ""
	var currentIndex = playerListPage * 7
	for i in range(0,7):
		if currentIndex > len(playerList) - 1:
			break
		var label = multiplayerMenuManager.options_players[i]
		var username = playerList.keys()[currentIndex]
		label.text = username
		label.visible = true
		multiplayerMenuManager.options_players_visible += 1
		currentIndex += 1
		await get_tree().create_timer(.1, false).timeout


func Interaction(alias : String):
	speaker_buttonpress.pitch_scale = randf_range(.8, 1)
	speaker_buttonpress.play()
	match alias:
		"right":
			branch_right.get_parent().get_child(1).Press()
			CycleOptions("right")
		"left":
			branch_left.get_parent().get_child(1).Press()
			CycleOptions("left")
		"window":
			branch_window.get_parent().get_child(1).Press()
			SelectOption()
		"exit":
			pass
#			has_exited = true
#			branch_exit.get_parent().get_child(1).Press()
#			viewing = false
#			board.TurnOffDisplay()
#			intro.DisableInteractionCrt()
#			await get_tree().create_timer(.3, false).timeout
#			intro.RevertCRT()
#			screenparent_multiplayer.visible = false
#			multiplayerMenuManager.options_players_visible = 0
#			for label in multiplayerMenuManager.options_players:
#				label.text = ""
#				label.visible = false
#			exit.exitAllowed = true

func CycleOptions(direction : String):
	match window_index:
		0:
			var optionsLength = len(multiplayerMenuManager.options_login) - 1
			if (direction == "right"):
				if multiplayerMenuManager.options_index < optionsLength:
					multiplayerMenuManager.options_index += 1
				else:
					multiplayerMenuManager.options_index = 0
			else:
				if multiplayerMenuManager.options_index > 0:
					multiplayerMenuManager.options_index -= 1
				else:
					multiplayerMenuManager.options_index = optionsLength
			HighlightOption("login", multiplayerMenuManager.options_index)
		2:
			var optionsLength = multiplayerMenuManager.options_players_visible - 1
			if (direction == "right"):
				if multiplayerMenuManager.options_index < optionsLength:
					multiplayerMenuManager.options_index += 1
				else:
					if playerListPage < maxListPages:
						playerListPage += 1
						multiplayerMenuManager.options_index = 0
						DrawNewPage()
					else:
						return
			else:
				if multiplayerMenuManager.options_index > 0:
					multiplayerMenuManager.options_index -= 1
				else:
					if playerListPage > 0:
						playerListPage -= 1
						multiplayerMenuManager.options_index = 6
						DrawNewPage()
					else:
						return
			HighlightOption("players", multiplayerMenuManager.options_index)
		1:
			var optionsLength = len(multiplayerMenuManager.options_invite) - 1
			if (direction == "right"):
				if multiplayerMenuManager.options_index < optionsLength:
					multiplayerMenuManager.options_index += 1
				else:
					multiplayerMenuManager.options_index = 0
			else:
				if multiplayerMenuManager.options_index > 0:
					multiplayerMenuManager.options_index -= 1
				else:
					multiplayerMenuManager.options_index = optionsLength
			HighlightOption("invite", multiplayerMenuManager.options_index)

func SelectOption():
	match window_index:
		0:
			multiplayerManager.accountName = multiplayerMenuManager.username_input.textField.text
			if multiplayerMenuManager.options_index == 0:
				if !multiplayerManager.loggedIn:
					multiplayerManager.connectToServer()
					await multiplayer.connected_to_server
					if !multiplayerManager.accountName:
						multiplayerManager.closeSession("noUsername")
						return false
					multiplayerManager.createNewMultiplayerUser.rpc(multiplayerManager.accountName)
			else:
				multiplayerManager.connectToServer()
				await multiplayer.connected_to_server
				multiplayerManager.doLoginStuff()
				
			var statusFlag = await multiplayerManager.loginStatus
			print(statusFlag)
			if statusFlag[0] != 0:
				multiplayerMenuManager.error_label.text = "ERROR: %s" % statusFlag[1]
				return
			MultiplayerStartup()
		1:
			if multiplayerMenuManager.options_index == 0:
				print("ACCEPT INVITE")
				CloseInvite("accept")
			else:
				print("DENY INVITE")
				CloseInvite("decline")
		2:
			var currentIndex = playerListPage * 7
			var userIndex = currentIndex + multiplayerMenuManager.options_index
			var playerID = playerList.values()[userIndex]
			multiplayerManager.inviteUser.rpc(playerID, multiplayerManager.accountName)

func OpenInvite(fromUsername, fromID):
	multiplayerMenuManager.screenparent_invite.visible = true
	multiplayerMenuManager.options_index = 0
	multiplayerMenuManager.invitee_label.text = fromUsername
	inviteeID = fromID
	window_index = 1
	HighlightOption("invite", 0)
	
func CloseInvite(action : String):
	if action == "accept":
		MultiplayerStartup()
		# Function call for starting a game goes here (Mitch can do that lol cause idk the rpcs for the server)
		return
	inviteeID = null
	MultiplayerStartup()


func HighlightOption(screen : String, optionIdx : int):
	match screen:
		"players":
			for label in multiplayerMenuManager.options_players:
				var actualLabel = label.get_child(0)
				if actualLabel.text.begins_with("["):
					var modified = actualLabel.text.erase(0,1)
					modified = modified.erase(len(modified) - 1, 1)
					actualLabel.text = modified
			var actualLabel = multiplayerMenuManager.options_players[optionIdx].get_child(0)
			actualLabel.text = "[%s]" % actualLabel.text
		"login":
			for sprite in multiplayerMenuManager.options_login:
				sprite.set_modulate(Color(0,1,0,0))
				var childText = sprite.get_child(0)
				childText.set_modulate(Color(0,0.9,0,1))
			multiplayerMenuManager.options_login[optionIdx].set_modulate(Color(0,1,0,1))
			multiplayerMenuManager.options_login[optionIdx].get_child(0).set_modulate(Color(0,0,0,1))
		"invite":
			for label in multiplayerMenuManager.options_invite:
				if label.text.begins_with("["):
					var modified = label.text.erase(0,1)
					modified = modified.erase(len(modified) - 1, 1)
					label.text = modified
			var label = multiplayerMenuManager.options_invite[optionIdx]
			label.text = "[%s]" % label.text
