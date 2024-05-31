extends Node

signal player_list(playerDict)
signal loginStatus(status)
signal keyReceived(status)

var accountName = null
var invitePendingIdx = null
var inMatch = false
var crtManager
var inviteMenu
var loggedIn = false
var timer : Timer

func _ready():
	multiplayer.connected_to_server.connect(func(): connectionTimer("stop"))
	multiplayer.server_disconnected.connect(_onServerDisconnected)

func connectionTimer(action):
	if action == "start":
		timer = Timer.new()
		GlobalVariables.get_current_scene_node().add_child(timer)
		inviteMenu.get_node("connecting").visible = true
		inviteMenu.get_node("connecting/AnimationPlayer").play("connecting")
		timer.timeout.connect(_onConnectionFail)
		timer.start(10)
	else:
		inviteMenu.get_node("connecting").visible = false
		inviteMenu.get_node("connecting/AnimationPlayer").stop()
		timer.queue_free()

func connectToServer():
	connectionTimer("start")
	var peer = ENetMultiplayerPeer.new()
	var url = "buckshotmultiplayer.net"
	if url == "buckshotmultiplayer.net": url = "connectviamultiplayerclient." + url
	var error = peer.create_client(url, 2095)
	if error:
		print("ERROR: %s" % error)
		return error
	multiplayer.set_multiplayer_peer(peer)

func attemptLogin():
	var keyFile = FileAccess.open("res://privatekey.key", FileAccess.READ)
	if !keyFile: 
		closeSession("noKey")
		multiplayer.multiplayer_peer = null
		return false
	verifyUserCreds.rpc(keyFile.get_buffer(keyFile.get_length()))

@rpc("any_peer")
func notifySuccessfulLogin(username):
	accountName = username
	inviteMenu.processLoginStatus("success")
	print("logged in as %s" % username)
	loggedIn = true

@rpc("any_peer")
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
		await get_tree().reload_current_scene()

@rpc("any_peer")
func receiveUserCreationStatus(return_value: bool): 
	if return_value == false:
		print("USER ALREADY EXISTS")
		closeSession("userExists")
	else:
		print("CREATED USER SUCCESSFULLY")
		loginStatus.emit() 
	
@rpc("any_peer")
func receivePrivateKey(keyString):
	var keyFile = FileAccess.open("res://privatekey.key", FileAccess.WRITE)
	keyFile.store_string(keyString)
	keyFile.close()
	attemptLogin()

@rpc("any_peer")
func receivePlayerList(dict):
	inviteMenu.updateUserList(dict)

@rpc("any_peer")
func receiveInvite(fromUsername, fromID):
	inviteMenu.receiveInvite(fromUsername, fromID)

@rpc("any_peer")
func receiveInviteStatus(username, status):
	crtManager.processInviteStatus(username, status)

@rpc("any_peer")
func receiveInviteList(list):
	inviteMenu.serverInviteList.emit(list)

@rpc("any_peer", "call_local") 
func acceptInvite(from):
	inviteMenu.showJoin()
	await inviteMenu.timerJoin.animation_finished 
	inviteMenu.joiningGameSection.visible = false
	crtManager.Interaction("exit")
	crtManager.intro.speaker_pillselect.play()
	await get_tree().create_timer(2.5, false).timeout
	crtManager.SetCRT(false)
	inMatch = true

@rpc("any_peer") 
func opponentDisconnect(): 
	inMatch = false
	loggedIn = false
	inviteMenu.get_node("opponentDisconnected").visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	await get_tree().create_timer(5).timeout
	await get_tree().reload_current_scene()
	pass

func leaveMatch():
	inMatch = false
	loggedIn = false
	multiplayer.multiplayer_peer = null
	inviteMenu.get_node("leavingMatch").visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	await get_tree().create_timer(5).timeout
	await get_tree().reload_current_scene()
	pass

# GHOST FUNCTIONS
#@rpc("any_peer") func requestUserExistsStatus(username : String): pass
@rpc("any_peer", "reliable") func requestNewUser(username: String) : pass
@rpc("any_peer") func verifyUserCreds(keyFileData): pass
@rpc("any_peer") func requestPlayerList(): pass
@rpc("any_peer") func createInvite(to : int): pass
@rpc("any_peer") func retractInvite(to): pass
@rpc("any_peer") func retractAllInvites(): pass
@rpc("any_peer") func getInvites(type): pass
@rpc("any_peer") func denyInvite(from): pass
