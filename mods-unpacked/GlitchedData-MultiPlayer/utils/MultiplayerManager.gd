extends Node

signal player_list(playerDict)
signal loginStatus(status)
signal keyReceived(status)

const AUTHORNAME_MODNAME_DIR := "GlitchedData-MultiPlayer"

var debug_mode = false

var version = "0.3.3"

var chat_enabled = true
var voice_enabled = true

var accountName = null
var invitePendingIdx = null
var inMatch = false
var crtManager
var inviteMenu
var loggedIn = false
var timer : Timer
var timerRunning = false
var url = "buckshotmultiplayer.net"
var keyLocation = "user"
var resetManager
var inCredits
var openedBriefcase
var opponentActive
var regex
var rpcMismatch = true

func _ready():
	if debug_mode:
		url = "localhost"
		keyLocation = "res"

	ModLoaderStore.mod_data[AUTHORNAME_MODNAME_DIR].load_configs()
	var config_object = ModLoaderConfig.get_config(AUTHORNAME_MODNAME_DIR, keyLocation)
	if (config_object == null):
		config_object = ModLoaderConfig.create_config(AUTHORNAME_MODNAME_DIR, keyLocation,
			{"url": url, "chat_enabled": chat_enabled, "voice_enabled": voice_enabled})
	else:
		url = config_object.data.url
		chat_enabled = config_object.data.chat_enabled
		voice_enabled = config_object.data.voice_enabled

	multiplayer.connected_to_server.connect(func(): connectionTimer("stop"))
	multiplayer.server_disconnected.connect(_onServerDisconnected)

	AddKey("mp_delete", KEY_DELETE)
	AddKey("mp_chat", KEY_T)
	
	if inMatch:
		inMatch = false
		loggedIn = false
		inCredits = false
		multiplayer.multiplayer_peer = null

	regex = RegEx.new()
	regex.compile("^[A-Za-z0-9 ~!@#%&_=:;'<>,/\\-\\$\\^\\*\\(\\)\\+\\{\\}\\|\\[\\]\\.\\?\\\"]+$")

func isValidString(input):
	return true if input.is_empty() or regex.search(input) != null else false

func AddKey(action, key):
	InputMap.add_action(action)
	var ev = InputEventKey.new()
	ev.keycode = key
	InputMap.action_add_event(action, ev)

func connectionTimer(action):
	if action == "start":
		timer = Timer.new()
		GlobalVariables.get_current_scene_node().add_child(timer)
		timer.timeout.connect(_onConnectionFail)
		timer.start(10)
		timerRunning = true
		await get_tree().create_timer(0.5, false).timeout
		if timerRunning:
			if not inviteMenu.signupSection.visible: inviteMenu.get_node("connecting").visible = true
			inviteMenu.get_node("connecting/AnimationPlayer").play("connecting")
	else:
		timerRunning = false
		inviteMenu.signupSection.visible = false
		inviteMenu.get_node("connecting").visible = false
		inviteMenu.get_node("connecting/AnimationPlayer").stop()
		inviteMenu.get_node("connectFail").visible = false
		loggedIn = false
		timer.queue_free()

func connectToServer():
	connectionTimer("start")
	var peer = ENetMultiplayerPeer.new()
	if url == "buckshotmultiplayer.net": url = "connectviamultiplayerclient." + url
	var error = peer.create_client(url, 2095)
	if error:
		print("ERROR: %s" % error)
		return error
	multiplayer.set_multiplayer_peer(peer)

func attemptLogin():
	var keyFile = FileAccess.open(keyLocation + "://privatekey.key", FileAccess.READ)
	if !keyFile: 
		closeSession("noKey")
		multiplayer.multiplayer_peer = null
		return false
	verifyUserCreds.rpc(keyFile.get_buffer(keyFile.get_length()), version)

@rpc("any_peer", "reliable")
func notifySuccessfulLogin(username):
	accountName = username
	inviteMenu.processLoginStatus("success")
	print("logged in as %s" % username)
	loggedIn = true

@rpc("any_peer", "reliable")
func closeSession(reason):
	print("SESSION TERMINATED\nReason: %s" % reason)
	loginStatus.emit(reason)
	loggedIn = false

func _onConnectionFail():
	inviteMenu.get_node("connecting").visible = false
	inviteMenu.get_node("connecting/AnimationPlayer").stop()
	inviteMenu.get_node("connectFail").visible = true
	multiplayer.multiplayer_peer = null

func _onServerDisconnected():
	multiplayer.multiplayer_peer = null
	print("Server Disconected")
	loggedIn = false
	if !inMatch && !inviteMenu.crtMenu.visible:
		inviteMenu.get_node("disconnected").visible = true
		await get_tree().create_timer(8).timeout
		inviteMenu.get_node("disconnected").visible = false
	elif !inMatch:
		return
	else:
		inMatch = false
		inviteMenu.get_node("disconnectedInGame").visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		await get_tree().create_timer(5).timeout
		resetManager.Reset()

@rpc("any_peer", "reliable")
func receiveUserCreationStatus(return_value: bool): 
	if return_value == false:
		print("USER ALREADY EXISTS")
		closeSession("userExists")
	else:
		print("CREATED USER SUCCESSFULLY")
		loginStatus.emit() 
	
@rpc("any_peer", "reliable")
func receivePrivateKey(keyString):
	var keyFile = FileAccess.open(keyLocation + "://privatekey.key", FileAccess.WRITE)
	keyFile.store_string(keyString)
	keyFile.close()
	attemptLogin()

@rpc("any_peer", "reliable")
func receivePlayerList(dict):
	inviteMenu.updateUserList(dict)

@rpc("any_peer", "reliable")
func receiveInvite(fromUsername, fromID):
	inviteMenu.receiveInvite(fromUsername, fromID)

@rpc("any_peer", "reliable")
func receiveInviteStatus(username, status):
	crtManager.processInviteStatus(username, status)

@rpc("any_peer", "reliable")
func receiveInviteList(list):
	inviteMenu.serverInviteList.emit(list)

@rpc("any_peer", "call_local", "reliable") 
func acceptInvite(from):
	inMatch = true
	inviteMenu.showJoin()
	await inviteMenu.timerJoin.animation_finished
	inviteMenu.joiningGameSection.visible = false
	crtManager.Interaction("exit")
	crtManager.intro.speaker_pillselect.play()
	await get_tree().create_timer(2.5, false).timeout
	crtManager.SetCRT(false)

@rpc("any_peer", "reliable") 
func opponentDisconnect():
	opponentActive = false
	if !inCredits:
		inMatch = false
		loggedIn = false
		inviteMenu.get_node("opponentDisconnected").visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		await get_tree().create_timer(5).timeout
		resetManager.Reset()
		pass

@rpc("any_peer", "reliable") 
func receiveChat(message):
	inviteMenu.addChatMessage(message, false)

@rpc("any_peer", "reliable") 
func receiveLeaderboard(list):
	inviteMenu.receiveLeaderboard(list)

# GHOST FUNCTIONS
#@rpc("any_peer", "reliable") func requestUserExistsStatus(_username : String): pass
@rpc("any_peer", "reliable") func requestNewUser(_username: String) : pass
@rpc("any_peer", "reliable") func verifyUserCreds(_keyFileData, version): pass
@rpc("any_peer", "reliable") func requestPlayerList(): pass
@rpc("any_peer", "reliable") func requestLeaderboard(): pass
@rpc("any_peer", "reliable") func createInvite(_to : int): pass
@rpc("any_peer", "reliable") func retractInvite(_to): pass
@rpc("any_peer", "reliable") func retractAllInvites(): pass
@rpc("any_peer", "reliable") func getInvites(_type): pass
@rpc("any_peer", "reliable") func denyInvite(_from): pass
@rpc("any_peer", "reliable") func sendChat(_message): pass
@rpc("any_peer", "reliable") func verifyDealer(_key, _playerID): pass
@rpc("any_peer", "reliable") func linkDealer(_id): pass
@rpc("any_peer", "reliable") func startDealer(): pass