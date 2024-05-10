extends "res://scripts/CrtManager.gd"

var screenparent_multiplayer : Node3D
var multiplayerManager
var multiplayerMenuManager
var playerList
var playerListPage = 0
var maxListPages
var inviteeID
var inviteeUsername
var refreshing
var deniedUsers = []
var joinSound = preload("res://audio/pill select1.ogg")

signal inviteStatus(status)

func _unhandled_input(event):
	if (event.is_action_pressed("ui_accept") && viewing):
		Interaction("window")
	if (event.is_action_pressed("exit game") && viewing):
		Interaction("exit")
	if (event.is_action_pressed("ui_left") && viewing):
		Interaction("left")
	if (event.is_action_pressed("ui_right") && viewing):
		Interaction("right")

func Bootup():
	inviteStatus.connect(receiveInviteStatus)
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	multiplayerMenuManager = screenparent_multiplayer.get_node("multiplayermenu")
	has_exited = false
	board.lock.material_override.albedo_color = Color(1, 1, 1, 0)
	screenparent_multiplayer.visible = true
	multiplayerMenuManager.username_input.SetViewing(true)
	window_index = 0
	if multiplayerManager.accountName != null:
		if !multiplayerManager.loggedIn:
			multiplayerManager.connectToServer()
			await multiplayer.connected_to_server
			multiplayerManager.doLoginStuff()
		for icon in iconbranches: icon.CheckState(window_index)
		anim_iconfade.play("fade in")
		await get_tree().create_timer(.5, false).timeout
		multiplayerMenuManager.options_index = 0
		MultiplayerStartup()
	else:
		multiplayerMenuManager.screenparent_login.visible = true
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
	multiplayerManager.requestPlayerList.rpc()
	playerList = await multiplayerManager.player_list
	playerList.erase(playerList.keys()[playerList.keys().find(multiplayerManager.accountName)])
	var numOfPlayers = len(playerList)
	maxListPages = (numOfPlayers/7) 
	DrawNewPage()
	refreshing = false
	refreshPlayerList()

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
		if multiplayerManager.invitePendingIdx:
			if i == multiplayerManager.invitePendingIdx[0] && playerListPage == multiplayerManager.invitePendingIdx[1]:
				multiplayerMenuManager.options_players[multiplayerMenuManager.options_index].get_child(0).text = "PENDING"
			else:
				multiplayerMenuManager.options_players[multiplayerMenuManager.options_index].get_child(0).text = "INVITE"

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
			if multiplayerManager.invitePendingIdx != null:
				multiplayerMenuManager.error_label_players.text = "ERROR: YOU HAVE A PENDING INVITE"
				clearError()
				return
			has_exited = true
			branch_exit.get_parent().get_child(1).Press()
			viewing = false
			board.TurnOffDisplay()
			intro.DisableInteractionCrt()
			await get_tree().create_timer(.3, false).timeout
			intro.RevertCRT()
			screenparent_multiplayer.visible = false
			multiplayerMenuManager.options_players_visible = 0
			for label in multiplayerMenuManager.options_players:
				label.text = ""
				label.visible = false
			exit.exitAllowed = true
			multiplayerMenuManager.username_input.resetInput()
			refreshing = false

func CycleOptions(direction : String):
	match window_index:
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
			multiplayerManager.connectToServer()
			await multiplayer.connected_to_server
			multiplayerManager.accountName = multiplayerMenuManager.username_input.textField.text.to_lower()
			multiplayerManager.doLoginStuff()
			var statusFlag = await multiplayerManager.loginStatus
			if statusFlag[0] != 0:
				if statusFlag[0] == 3 or statusFlag[0] == 1:
					multiplayerManager.connectToServer()
					await multiplayer.connected_to_server
					multiplayerManager.createNewMultiplayerUser.rpc(multiplayerManager.accountName)
					await multiplayerManager.loginStatus
					multiplayerManager.doLoginStuff()
				else:
					multiplayerMenuManager.error_label.text = "ERROR: %s" % statusFlag[1]
					multiplayerManager.accountName = null
					clearError()
					return
			multiplayerMenuManager.screenparent_login.visible = false
			for icon in iconbranches: icon.CheckState(window_index)
			anim_iconfade.play("fade in")
			await get_tree().create_timer(.5, false).timeout
			MultiplayerStartup()
		1:
			if multiplayerMenuManager.options_index == 0:
				CloseInvite("accept")
			else:
				CloseInvite("decline")
		2:
			if !multiplayerMenuManager.options_players[multiplayerMenuManager.options_index].visible:
				return
			if multiplayerManager.invitePendingIdx != null:
				multiplayerMenuManager.error_label_players.text = "ERROR: YOU ALREADY HAVE A PENDING INVITE"
				clearError()
				return
			var currentIndex = playerListPage  * 7
			var userIndex = currentIndex + multiplayerMenuManager.options_index
			multiplayerManager.invitePendingIdx = [multiplayerMenuManager.options_index, playerListPage]
			var playerID = playerList.values()[userIndex]
			multiplayerManager.inviteUser.rpc(playerID, multiplayerManager.accountName)

func OpenInvite(fromUsername, fromID):
	if fromUsername in deniedUsers:
		return
	multiplayerManager.invitePendingIdx = 0
	multiplayerMenuManager.screenparent_invite.visible = true
	multiplayerMenuManager.options_index = 0
	multiplayerMenuManager.invitee_label.text = fromUsername
	inviteeUsername = fromUsername
	inviteeID = fromID
	window_index = 1
	HighlightOption("invite", 0)
	
func CloseInvite(action : String):
	var roundManager = multiplayerManager.get_child(0)
	multiplayerManager.invitePendingIdx = null
	if action == "accept":
		roundManager.receiveJoinMatch.rpc()
		sendInviteStatus.rpc_id(inviteeID, "accept")
		Interaction("exit")
		var player = AudioStreamPlayer2D.new()
		GlobalVariables.get_current_scene_node().add_child(player)
		player.stream = joinSound
		player.volume_db = 2.5
		player.play()
		await get_tree().create_timer(2.5, false).timeout
		SetCRT(false)
		inviteeID = null
		inviteeUsername = null
		return
	sendInviteStatus.rpc_id(inviteeID, "deny")
	deniedUsers.append(inviteeUsername)
	inviteeID = null
	inviteeUsername = null
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
		"invite":
			for label in multiplayerMenuManager.options_invite:
				if label.text.begins_with("["):
					var modified = label.text.erase(0,1)
					modified = modified.erase(len(modified) - 1, 1)
					label.text = modified
			var label = multiplayerMenuManager.options_invite[optionIdx]
			label.text = "[%s]" % label.text
			
func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE) && viewing:
		Interaction("exit")
	if Input.is_key_pressed(KEY_L) && viewing && multiplayerManager.loggedIn && multiplayerManager.invitePendingIdx == null:
		multiplayerManager.closeSession("Logged Out")
		multiplayerManager.accountName = null
		multiplayerMenuManager.screenparent_players.visible = false
		Interaction("exit")
		
func refreshPlayerList():
	refreshing = true
	while refreshing == true:
		await get_tree().create_timer(1, false).timeout
		multiplayerManager.requestPlayerList.rpc()
		playerList = await multiplayerManager.player_list
		playerList.erase(playerList.keys()[playerList.keys().find(multiplayerManager.accountName)])
		var numOfPlayers = len(playerList)
		maxListPages = (numOfPlayers/7) 
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
			if multiplayerManager.invitePendingIdx:
				if i == multiplayerManager.invitePendingIdx[0] && playerListPage == multiplayerManager.invitePendingIdx[1]:
					multiplayerMenuManager.options_players[i].get_child(0).text = "PENDING"
				else:
					multiplayerMenuManager.options_players[i].get_child(0).text = "INVITE"
		HighlightOption("players", multiplayerMenuManager.options_index)

func clearError():
	await get_tree().create_timer(5, false).timeout
	multiplayerMenuManager.error_label_players.text = ""
	multiplayerMenuManager.error_label.text = ""

@rpc("any_peer")
func sendInviteStatus(status):
	inviteStatus.emit(status)
	
func receiveInviteStatus(status):
	multiplayerManager.invitePendingIdx = null
	if status == "accept":
		var roundManager = multiplayerManager.get_child(0)
		roundManager.receiveJoinMatch.rpc()
		Interaction("exit")
		var player = AudioStreamPlayer2D.new()
		GlobalVariables.get_current_scene_node().add_child(player)
		player.stream = joinSound
		player.volume_db = 2.5
		player.play()
		await get_tree().create_timer(2.5, false).timeout
		SetCRT(false)
	else:
		multiplayerMenuManager.error_label_players.text = "ERROR: INVITE DECLINED"
