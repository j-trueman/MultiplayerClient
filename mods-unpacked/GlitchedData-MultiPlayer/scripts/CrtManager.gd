extends Node

const Board = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/LeaderboardManager.gd")
const CrtIcon = preload("res://scripts/CrtIcon.gd")
const ExitManager = preload("res://scripts/UserExit.gd")
const InteractionBranch = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/InteractionBranch.gd")
const IntroManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/IntroManager.gd")
const PartitionBranch = preload("res://scripts/PartitionBranch.gd")

@export var exit : ExitManager
var viewing = false

@export var intro : IntroManager
@export var bathroom_normal : VisualInstance3D
@export var bathroom_broken : VisualInstance3D
@export var mask : Node3D

@export var objarray_normal : Array[Node3D]
@export var objarray_broken : Array[Node3D]
@export var anim_intro : AnimationPlayer
@export var array_bootup : Array[Node3D]
@export var array_bootuplogo : Array[Node3D]
@export var array_partbranch : Array[PartitionBranch]
@export var array_stats : Array[Node3D]
@export var screenparent_leaderboard : Node3D
@export var screenparent_stats : Node3D

var window_index = 3
@export var iconbranches : Array[CrtIcon]
@export var anim_iconfade : AnimationPlayer
@export var board : Board

@export var speaker_playerwalk : AudioStreamPlayer2D
@export var speaker_bootuploop : AudioStreamPlayer2D
@export var speaker_shutdown : AudioStreamPlayer2D
@export var speaker_consolebeep : AudioStreamPlayer2D
@export var speaker_buttonpress : AudioStreamPlayer2D
@export var speaker_navbeep : AudioStreamPlayer2D
@export var speaker_melody : AudioStreamPlayer2D
@export var speaker_melodyhide : AudioStreamPlayer2D

var selection_range1 = 1
var selection_range2 = 12

func DisableCRT():
	SetCRT(false)

@export var branch_right : InteractionBranch
@export var branch_left : InteractionBranch
@export var branch_window : InteractionBranch
@export var branch_exit : InteractionBranch

var has_exited = false

func CycleWindow():
	board.lock.material_override.albedo_color = Color(1, 1, 1, 0)
	selection_range1 = 1
	selection_range2 = 12
	board.ClearDisplay()
	window_index += 1
	if window_index == 4: window_index = 0
	for icon in iconbranches: icon.CheckState(window_index)
	if (window_index == 3): 
		board.nocon.visible = false
		screenparent_leaderboard.visible = false
		screenparent_stats.visible = true
	else: 
		screenparent_leaderboard.visible = true
		screenparent_stats.visible = false
		board.nocon.visible = true
	if (window_index == 0): board.PassLeaderboard(selection_range1, selection_range2, "top")
	if (window_index == 1): 
		board.lock.visible = true
		board.PassLeaderboard(selection_range1, selection_range2, "overview")
	if (window_index == 2): board.PassLeaderboard(1, 49, "friends") #range ignored

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
