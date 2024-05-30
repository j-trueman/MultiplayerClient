extends "res://scripts/CrtManager.gd"

var screenparent_multiplayer : Node3D
var multiplayerManager
var inviteeUsername
var inviteeID
var deniedUsers = []

signal inviteStatus(username, status)

func _ready():
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")	
	inviteStatus.connect(processInviteStatus)
	multiplayerManager.loginStatus.connect(processLoginStatus)
	multiplayerManager.crtManager = self

func _unhandled_input(event):
	if (event.is_action_pressed("ui_accept") && viewing):
		Interaction("window")
	if (event.is_action_pressed("exit game") && viewing):
		Interaction("exit")
	if (event.is_action_pressed("ui_left") && viewing):
		Interaction("left")
	if (event.is_action_pressed("ui_right") && viewing):
		Interaction("right")

func Interaction(alias : String):
	speaker_buttonpress.pitch_scale = randf_range(.8, 1)
	speaker_buttonpress.play()
	match alias:
		"right":
			branch_right.get_parent().get_child(1).Press()
		"left":
			branch_left.get_parent().get_child(1).Press()
		"window":
			branch_window.get_parent().get_child(1).Press()
		"exit":
			multiplayerManager.inviteMenu.crtMenu.visible = false
			branch_exit.get_parent().get_child(1).Press()
			viewing = false
			board.TurnOffDisplay()
			intro.DisableInteractionCrt()
			await get_tree().create_timer(.3, false).timeout
			intro.RevertCRT()
			exit.exitAllowed = true

func Bootup():
	viewing = true
	if !multiplayerManager.loggedIn:
		multiplayerManager.connectToServer()
		await multiplayer.connected_to_server
		if multiplayerManager.attemptLogin() == false:
			multiplayerManager.inviteMenu.signupSection.visible = true
		else:
			multiplayerManager.inviteMenu.playerListSection.visible = true
	await get_tree().create_timer(0.5, false).timeout
	multiplayerManager.inviteMenu.crtMenu.visible = true
	intro.EnabledInteractionCRT()
	exit.exitAllowed = false

func processLoginStatus(statusFlag, reason):
	if statusFlag == 0:
		multiplayerManager.inviteMenu.playerListSection.visible = true
		multiplayerManager.inviteMenu.signupSection.visible = false
		multiplayerManager.requestPlayerList.rpc()
	if statusFlag == 1:
		multiplayerManager.connectToServer()
		await multiplayer.connected_to_server
		multiplayerManager.requestNewUser.rpc(multiplayerManager.inviteMenu.usernameInput.text)
		var success = await multiplayerManager.keyReceived
		if !success:
			print("could not create user")
			return false
		multiplayerManager.attemptLogin()
		return
	else:
		return

func SetCRT(state : bool):
	if (state):
		bathroom_normal.set_layer_mask_value(1, false)
		bathroom_broken.visible = true
		for obj in objarray_normal: obj.visible = false
		for obj in objarray_broken: obj.visible = true
		mask.visible = true
	else:
		bathroom_normal.set_layer_mask_value(1, true)
		bathroom_broken.visible = false
		for obj in objarray_normal: obj.visible = true
		for obj in objarray_broken: obj.visible = false
		mask.visible = false
		
func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE) && viewing:
		Interaction("exit")
	
func processInviteStatus(username, status):
	multiplayerManager.invitePendingIdx = null
	match status:
		"accept":
			if !multiplayerManager.inMatch:
				multiplayerManager.inMatch = true
				intro.roundManager.playerData.playername = multiplayerManager.accountName.to_upper()
				intro.dealerName.text = username.to_upper()
				multiplayerManager.inviteMenu.showReady(username)
				await multiplayerManager.inviteMenu.timerAccept.animation_finished
				multiplayerManager.inviteMenu.gameReadySection.visible = false
				Interaction("exit")
				intro.speaker_pillselect.play()
				await get_tree().create_timer(2.5, false).timeout
				SetCRT(false)
		"busy":
#			multiplayerMenuManager.error_label_players.text = "ERROR: USER HAS PENDING INVITE, TRY AGAIN"
			inviteeUsername = null
		"deny":
#			multiplayerMenuManager.error_label_players.text = "ERROR: INVITE DECLINED"
			inviteeUsername = null
		_:
#			multiplayerMenuManager.error_label_players.text = "INVITE RETRACTED"
			inviteeUsername = null
	inviteeID = null
		

