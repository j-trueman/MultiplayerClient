extends "res://scripts/CrtManager.gd"

var screenparent_multiplayer : Node3D
var multiplayerManager
var inviteeID
var deniedUsers = []

func _ready():
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")	
	multiplayerManager.crtManager = self

	var file = FileAccess.open("res://mods-unpacked/GlitchedData-MultiPlayer/media/crt_bootup_fix.mp3", FileAccess.READ)
	var buffer = file.get_buffer(file.get_length())
	var stream = AudioStreamMP3.new()
	stream.data = buffer
	speaker_bootuploop.stream = stream

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
			multiplayerManager.inviteMenu.get_node("connecting").visible = false
			multiplayerManager.inviteMenu.get_node("connectFail").visible = false
			multiplayerManager.inviteMenu.usernameInput.text = ""
			branch_exit.get_parent().get_child(1).Press()
			viewing = false
			board.TurnOffDisplay()
			intro.DisableInteractionCrt()
			await get_tree().create_timer(.3, false).timeout
			intro.RevertCRT()
			exit.exitAllowed = true

func Bootup():
	exit.exitAllowed = false
	viewing = true
	await get_tree().create_timer(0.5, false).timeout
	if !multiplayerManager.loggedIn:
		multiplayerManager.connectToServer()
		await multiplayer.connected_to_server
		multiplayerManager.attemptLogin()
	else:
		multiplayerManager.inviteMenu.processLoginStatus("success")
	intro.EnabledInteractionCRT()

func SetCRT(state : bool):
	bathroom_normal.set_layer_mask_value(1, not state)
	bathroom_broken.visible = state
	for obj in objarray_normal: obj.visible = not state
	for obj in objarray_broken: obj.visible = state
	mask.visible = state
	GlobalVariables.get_current_scene_node().get_node("intro parent/bathroom door/interaction branch_bathroom door").interactionInvalid = state

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE) && viewing:
		Interaction("exit")
	if Input.is_key_pressed(KEY_BACKSPACE) && not event.is_echo():
		multiplayerManager.inviteMenu.usernameInput.text = multiplayerManager.inviteMenu.usernameInput.text.erase(len(multiplayerManager.inviteMenu.usernameInput.text) -1, 1)

func processInviteStatus(username, status):
	multiplayerManager.invitePendingIdx = null
	match status:
		"accept":
			if !multiplayerManager.inMatch:
				multiplayerManager.inMatch = true
				intro.roundManager.playerData.playername = multiplayerManager.accountName.to_upper()
				print(username)
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
			pass
		"deny":
#			multiplayerMenuManager.error_label_players.text = "ERROR: INVITE DECLINED"
			pass
		_:
#			multiplayerMenuManager.error_label_players.text = "INVITE RETRACTED"
			pass
	inviteeID = null


