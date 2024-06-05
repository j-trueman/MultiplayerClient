extends "res://scripts/CrtManager.gd"

const savePath := "user://buckshotmultiplayer.shell"
var data = {}

var screenparent_multiplayer : Node3D
var multiplayerManager
var mrm
var inviteeID
var deniedUsers = []
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
		"\n %%%%%%%#      *%%%%%#       #%%%%%##  %%%%%##%%%%# #%%%%#   %%%%%% %%%%%%*     %%%%%*       #%%%%%%" +
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
	array_bootuplogo[8].text = "VERSION 0.1.0 (PUBLIC BETA)"
	array_bootuplogo[9].text = "Any created user accounts\nmay be suject to deletion\nfor any reason at any time."

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
		"left":
			branch_left.get_parent().get_child(1).Press()
			if multiplayerManager.inviteMenu.signupSection.visible and multiplayerManager.inviteMenu.usernameInput.caret_column > 0:
				multiplayerManager.inviteMenu.usernameInput.caret_column -= 1
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
	else:
		multiplayerManager.inviteMenu.processLoginStatus("success")

func Bootup_FirstWelcome():
	if (FileAccess.file_exists(savePath)):
		var file_load = FileAccess.open(savePath, FileAccess.READ)
		data = file_load.get_var()
		file_load.close()
		if data.version == "0.1.0": return
	speaker_melody.pitch_scale = 1.6
	speaker_melody.play()
	for line in array_bootuplogo: 
		line.visible = true
		await get_tree().create_timer(.07, false).timeout
	await get_tree().create_timer(7, false).timeout
	for line in array_bootuplogo: line.visible = false
	speaker_melody.stop()
	speaker_melodyhide.play()
	data.version = "0.1.0"
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
				mrm.opponent = username.to_upper()
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


