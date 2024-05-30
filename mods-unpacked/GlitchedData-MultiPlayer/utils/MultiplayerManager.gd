extends Node

signal server_disconnected
signal player_list(playerDict)
signal loginStatus(statusFlag)
signal keyReceived(status)

var accountName = null
var invitePendingIdx = null
var inMatch = false
var crtManager
var inviteMenu
var loggedIn = false

func _ready():
	multiplayer.connection_failed.connect(_onConnectionFail)
	multiplayer.server_disconnected.connect(_onServerDisconnected)
	
func connectToServer():
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
		return false
	verifyUserCreds.rpc(keyFile.get_buffer(keyFile.get_length()))

@rpc("any_peer")
func notifySuccessfulLogin(username):
	accountName = username
	loginStatus.emit(0, "SUCCESS")
	loggedIn = true

@rpc("any_peer")
func closeSession(reason):
	multiplayer.multiplayer_peer = null
	print("MULTIPLAYER SESSION TERMINATED: '%s'" % reason)
	await get_tree().create_timer(1).timeout
	if reason == "nonexistentUser":
		loginStatus.emit(1, "User Does Not Exist.")
	elif reason == "incorrectCreds":
		loginStatus.emit(2, "Incorrect Credentials.")
	elif reason == "noKey":
		loginStatus.emit(3, "No User Key Detected.")
	elif reason == "noUsername":
		loginStatus.emit(3, "You didn't set a username.")
	elif reason == "userExists":
		loginStatus.emit(4, "User already exists")
	else:
		loginStatus.emit(-1, "Unknown Error.")
	loggedIn = false

func _onConnectionFail():
	multiplayer.multiplayer_peer = null

func _onServerDisconnected():
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()
	print("Server Disconected")

@rpc("any_peer")
func receiveUserCreationStatus(return_value: bool): 
	if return_value == false:
		print("USER ALREADY EXISTS")
		closeSession("userExists")
	else:
		print("CREATED USER SUCCESSFULLY")
		loginStatus.emit(5) 
	
@rpc("any_peer")
func receivePrivateKey(keyString):
	var keyFile = FileAccess.open("res://privatekey.key", FileAccess.WRITE)
	keyFile.store_string(keyString)
	keyFile.close()
	keyReceived.emit(true)

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

# GHOST FUNCTIONS
@rpc("any_peer") func requestUserExistsStatus(username : String): pass
@rpc("any_peer", "reliable") func requestNewUser(username: String) : pass
@rpc("any_peer") func verifyUserCreds(keyFileData): pass
@rpc("any_peer") func requestPlayerList(): pass
@rpc("any_peer") func createInvite(to : int): pass
@rpc("any_peer") func retractInvite(to): pass
@rpc("any_peer") func retractAllInvites(): pass
@rpc("any_peer") func getInvites(type): pass
@rpc("any_peer") func denyInvite(from): pass
