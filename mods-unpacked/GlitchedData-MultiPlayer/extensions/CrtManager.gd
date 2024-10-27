extends "res://scripts/CrtManager.gd"

const savePath := "user://buckshotmultiplayer.shell"
var data = {}

var screenparent_multiplayer : Node3D
var multiplayerManager
var mrm
var inviteeID
var waitingForOpponent = false
var waitingTimer = 0.0
var waitingMessage = "WAITING FOR OPPONENT ..."
var ascii = [	  "%%%%%%%*   =%%#%## #%%##     %%%%%%*  #%%#%#%%%%#   #%%%%   #%%%%% +%%%%%%     #%%%%#     ##%######%" +
		"\n%%%%*%%%%   %%%%#= ##%%*    %%%##%%#  *#%%%+##%%*  +%# #%    %%%#=  #%%%#     #%%=%%%#    %%%%%%%%%%" +
		"\n %%%  %%%    %%%     %     *%%   #%%    %%   #%    #%  %#    %%%+    *%%     %%%   #%%*  #%*  %%# #%",
		  " %%%  %%%    %%%     %     %%%    %%    %%  #%+    %#  *%    %%%+    %%#    #%%%    %%%  #%   %%%  #" +
		"\n %%%  %%%    %%%     %    #%%%    %#    %%  ##     %%   *    %%%+    #%#    %%%     %%%       %%%  =" +
		"\n %%%  #%%    %%%     #    #%%           %% #%      %%#       %%%+    %%%    #%#     *%%#      %%%",
		  " %%%  %%%    %%%     %    %%%           %% #%      %%%%      %%%     %%%    %%#     *%%#      %%%" +
		"\n %%%%%%#     %%%     #    %%%           %%#%*      #%%%%#    %%%*    #%%    %%#      %%#      %%%" +  
		"\n %%%#%%%#    %%%     #    %%%           %%%%%       %%%%%    %%%%%%%%%%#    %%#      %%#      %%%",
		  " %%%  #%%    %%%     #+   %%%           %%#%%       #%%%%#   %%%# *%%#%#    #%%      %%%      %%%" +
		"\n %%%  #%%#   %%%     #*   %%%           %% %%#        #%%%   %%%     #%%    #%%      %%%      %%%" +
		"\n %%%  #%%%   %%%     *+   #%%           %% #%%         #%%   %%%     %%%    #%#     %%%#      %%%",
		  " %%%   %%%   %%%     #    %%%      %    %% *%%#    #    %%   %%%     %%%    %%%     #%#       %%%" +
		"\n %%%  #%%*   #%%     %    +%%#    %#    %%  #%%*   %#   %%   %%%     %%%    %%%%    %%%       %%%" +
		"\n %%%  %%%    %%%+   *#     #%#    #%    %%   %%#   %#   ##   %%%     *%%     #%#   #%%*       #%%",
		  " %%% *%%#     %%#  *%*      %%#  #%%   %%%*  %%%   %%* ##+   *%%*    %%%%    %%%#  %%#       #%%#" +
		"\n%%%%%%%#      *%%%%%#       #%%%%%##  %%%%%##%%%%# #%%%%#   %%%%%% %%%%%%*     %%%%%*       #%%%%%%" +
		"\n                %%##          #%%*                   #%                         ###                 ",
                                                                                                 
		  "%%%#    %%%% %%%%   %%% %%%    %%%%%%%#% %%%* %%% %%%% %%%        %%%*   %%%   %%  %%%%%%% #%%%%%%%" +
		"\n#%%%%  %%%%% *%%    %%   %%       %%%    %%%  %%%  #%% %%%       %%%%%    %%% %%   %%%      %%   %%" +
		"\n#%%%%%%%%%%%  %%    %%   %%       %%#    %%%  %%%%%%%# %%%      #%# %%%    %%%%    %%%%%%   %%%%%%",
		  "#%%*%%%% %%%  %%    %%   %%       %%%    %%%  %%%      %%%      %%%%%%%     %%%    %%%      %%*#%%" +
		"\n%%% %%%  %%%  %%%%%#%%  *%%%##%%  %%%    %%%# %%%%     %%%%%%%%%%#   %%%    %%%    %%%%%%%%%%%%  %%%" +
		"\n                 ##                                                         *##"]
var logo_z_positions = [-1.074, -0.924, -0.776, -0.625, -0.477, -0.325, -0.155, -0.009]

func _ready():
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	mrm = get_tree().root.get_node("MultiplayerManager/MultiplayerRoundManager")
	multiplayerManager.crtManager = self

	var file = FileAccess.open("res://mods-unpacked/GlitchedData-MultiPlayer/media/crt_bootup_fix.mp3", FileAccess.READ)
	var buffer = file.get_buffer(file.get_length())
	var stream = AudioStreamMP3.new()
	stream.data = buffer
	stream.loop = true
	stream.loop_offset = 6.0
	speaker_bootuploop.stream = stream
	
	for i in range(8):
		array_bootuplogo[i].font_size = 18
		array_bootuplogo[i].position.x = -1.5
		array_bootuplogo[i].position.z = logo_z_positions[i]
		array_bootuplogo[i].text = ascii[i]
	array_bootuplogo[8].text = "VERSION " + multiplayerManager.version + " (PUBLIC BETA)"
	array_bootuplogo[9].text = "Any created user accounts\nmay be subject to deletion\nfor any reason at any time."

func _process(delta):
	if mrm.actionReady_smart:
		waitingTimer += delta
		if waitingTimer > 2.0 and not waitingForOpponent:
			waitingForOpponent = true
			exit.label.text = waitingMessage
			exit.anim.stop()
			exit.label.self_modulate = Color(1, 1, 1, 1)
	else:
		waitingTimer = 0.0
		if waitingForOpponent:
			waitingForOpponent = false
			if exit.label.text == waitingMessage: exit.anim.play("fade out")

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
			if multiplayerManager.inviteMenu.signupSection.visible and multiplayerManager.inviteMenu.usernameInput.caret_column < multiplayerManager.inviteMenu.usernameInput.text.length():
				multiplayerManager.inviteMenu.usernameInput.caret_column += 1
			multiplayerManager.inviteMenu.toggleLeaderboard()
		"left":
			branch_left.get_parent().get_child(1).Press()
			if multiplayerManager.inviteMenu.signupSection.visible and multiplayerManager.inviteMenu.usernameInput.caret_column > 0:
				multiplayerManager.inviteMenu.usernameInput.caret_column -= 1
			multiplayerManager.inviteMenu.toggleLeaderboard()
		"window":
			if multiplayerManager.inviteMenu.usernameInput.has_focus():
				multiplayerManager.inviteMenu.requestUsername()
			branch_window.get_parent().get_child(1).Press()
		"exit":
			if multiplayerManager.timerRunning: multiplayerManager.timer.queue_free()
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
	await Bootup_FirstWelcome()
	exit.exitAllowed = false
	viewing = true
	await get_tree().create_timer(0.5, false).timeout
	intro.EnabledInteractionCRT()
	if !multiplayerManager.loggedIn:
		multiplayerManager.connectToServer()
		await multiplayer.connected_to_server
		multiplayerManager.attemptLogin()
		await get_tree().create_timer(1.5, false).timeout
		if multiplayerManager.rpcMismatch:
			multiplayerManager.inviteMenu.rpcMismatch()
	else:
		multiplayerManager.inviteMenu.processLoginStatus("success")

func Bootup_FirstWelcome():
	if (FileAccess.file_exists(savePath)):
		var file_load = FileAccess.open(savePath, FileAccess.READ)
		data = file_load.get_var()
		file_load.close()
		if data.version == multiplayerManager.version: return
	speaker_melody.pitch_scale = 1.6
	speaker_melody.play()
	for line in array_bootuplogo: 
		line.visible = true
		await get_tree().create_timer(.07, false).timeout
	await get_tree().create_timer(7, false).timeout
	for line in array_bootuplogo: line.visible = false
	speaker_melody.stop()
	speaker_melodyhide.play()
	data.version = multiplayerManager.version
	var file_save = FileAccess.open(savePath, FileAccess.WRITE)
	file_save.store_var(data)
	file_save.close()

func SetCRT(state : bool):
	bathroom_normal.set_layer_mask_value(1, not state)
	bathroom_broken.visible = state
	for obj in objarray_normal: obj.visible = not state
	for obj in objarray_broken: obj.visible = state
	mask.visible = state
	intro.intbranch_bathroomdoor.interactionInvalid = state
	intro.intbranch_crt.interactionAllowed = state

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE) && viewing:
		Interaction("exit")
		
func processInviteStatus(username, status):
	multiplayerManager.invitePendingIdx = null
	var userObject
	for user in multiplayerManager.inviteMenu.userList.get_children():
		if user.username == username:
			userObject = user
			break
	match status:
		"accept":
			if not multiplayerManager.inMatch:
				multiplayerManager.inMatch = true
				for user in multiplayerManager.inviteMenu.userList.get_children():
					if user.inviteButton.text == "PENDING":
						user.inviteButton.text = "INVITE"
						user.inviteButton.disabled = false
				multiplayerManager.inviteMenu.outgoingButton.queue_free()
				userObject.override = false
				userObject.setStatus(true)
				if multiplayerManager.inviteMenu.popupVisible:
					multiplayerManager.inviteMenu.removePopup()
				intro.roundManager.playerData.playername = multiplayerManager.accountName.to_upper()
				multiplayerManager.inviteMenu.showReady(username)
				await multiplayerManager.inviteMenu.timerAccept.animation_finished
				multiplayerManager.inviteMenu.gameReadySection.visible = false
				Interaction("exit")
				intro.speaker_pillselect.play()
				await get_tree().create_timer(2.5, false).timeout
				SetCRT(false)
		"busy":
			userObject.override = false
			userObject.setStatus(true)
		"deny":
			print(username + " denied")
			userObject.override = true
			userObject.inviteButton.disabled = true
			userObject.inviteButton.text = "DECLINED"
		"cancel":
			for invite in multiplayerManager.inviteMenu.inviteList.get_children():
				if invite.inviteFromUsername == username:
					invite.queue_free()
			if multiplayerManager.inviteMenu.popupVisible and multiplayerManager.inviteMenu.popupInvite.inviteFromUsername == username:
				multiplayerManager.inviteMenu.removePopup()
	inviteeID = null