extends Node

signal player_connected(peerId, playerInfo)
signal player_disconnected(peerId)
signal server_disconnected
signal player_list(playerDict)
signal loginStatus(statusFlag)

var players = {}
#var currentLobbyId = null
#var is_host
var accountName = null
var sessionEnded
var loggedIn = false
var peer

func _ready():
#	multiplayer.peer_connected.connect(_onPlayerConnected)
	multiplayer.peer_disconnected.connect(_onPlayerDisconnected)
	multiplayer.connected_to_server.connect(_onConnectedOk)
	multiplayer.connection_failed.connect(_onConnectionFail)
	multiplayer.server_disconnected.connect(_onServerDisconnected)

func connectToServer():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client("localhost", 2244)
	if error:
		print("ERROR: %s" % error)
		return error
	multiplayer.set_multiplayer_peer(peer)

func reconnect():
	connectToServer()
	await multiplayer.connected_to_server
	print("\nSUCCESSFULLY CONNECTED TO SERVER. ATTEMPTING LOGIN")
	doLoginStuff()

func doLoginStuff():
	var fileExists = FileAccess.file_exists("res://privatekey.key")
	if fileExists:
		var keyFile = getUserKey()
		verifyUserCreds.rpc(accountName, keyFile.save_to_string())
	else:
		closeSession("noKey")

func getUserKey():
	var keyFile = CryptoKey.new()
	var error = keyFile.load("res://privatekey.key")
	if error:
		return false
	return keyFile

func getUsernameFromFile():
	var f = FileAccess.open("user://mpuser.txt", FileAccess.READ)
	if !f:
		return null
	var line = f.get_line()
	f.close()
	print(line)
	return line

@rpc("authority")
func notifySuccessfulLogin():
	print("SUCCESSFULLY LOGGED IN AS %s" % accountName)
	loginStatus.emit(0, "SUCCESS")
	loggedIn = true

@rpc("authority")
func closeSession(reason):
	multiplayer.multiplayer_peer = null
	loggedIn = false
	sessionEnded = true
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

func removeMultiplayerPeer():
	multiplayer.multiplayer_peer = null

#func _onPlayerConnected(id):
#	registerPlayer.rpc_id(id, accountName)

@rpc("any_peer", "reliable")
func registerPlayer(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _onPlayerDisconnected(id):
#	if is_host:
#		closeLobby.rpc(id)
	player_disconnected.emit(id)

func _onConnectedOk():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = accountName
	player_connected.emit(peer_id, accountName)

func _onConnectionFail():
	multiplayer.multiplayer_peer = null

func _onServerDisconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	print("Server Disconected")
	if !sessionEnded:
		reconnect()

#@rpc("any_peer")
#func receiveLobbyList(lobby_list):
#	print("PUBLIC_LOBBIES:\n")
#	for lobby in lobby_list:
#		print("%s" % lobby)
#		for info in lobby_list[lobby]:
#			print("\t%s - %s" % [info, lobby_list[lobby][info]])
#		print("")

#@rpc("any_peer")
#func receive_lobby_id(lobby_id):
#	currentLobbyId = lobby_id

@rpc("any_peer")
func receiveUserCreationStatus(return_value: bool): 
	if return_value == false:
		print("USER ALREADY EXISTS")
		closeSession("userExists")
	else:
		print("CREATED USER SUCCESSFULLY")
		loginStatus.emit(5) 

@rpc("any_peer") 
func requestSenderUsername():
	receiveSenderUsername.rpc(accountName)
	
@rpc("authority")
func receiveUserKey(keyString):
	var keyFile = CryptoKey.new()
	keyFile.load_from_string(keyString)
	keyFile.save("res://privatekey.key")
	doLoginStuff()

@rpc("authority")
func receivePlayerList(dict):
	player_list.emit(dict)

@rpc("authority")
func receiveInvite(fromUsername, fromID):
	var crtManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/crt manager")
	crtManager.OpenInvite(fromUsername, fromID)

# GHOST FUNCTIONS
#@rpc("any_peer") func closeLobby(): pass
#@rpc("any_peer", "reliable") func create_lobby(): pass
#@rpc("any_peer") func requestLobbyList(): pass
@rpc("any_peer", "reliable") func createNewMultiplayerUser(username: String) : pass
@rpc("any_peer") func verifyUserCreds(username: String, key): pass
@rpc("any_peer") func receiveSenderUsername(username): pass
@rpc("any_peer") func requestPlayerList(): pass
@rpc("any_peer") func inviteUser(id, sender): pass

# DEBUG INPUTS
func _input(ev):
#	if Input.is_key_pressed(KEY_C):
#		create_lobby.rpc(2, "round robin", "public")
#		is_host = true
#	if Input.is_key_pressed(KEY_X):
#		if currentLobbyId == null:
#			print("YOU ARE NOT IN A LOBBY")
#			return false
#		closeLobby.rpc(currentLobbyId)
#		currentLobbyId = null
#	if Input.is_key_pressed(KEY_V):
#		create_lobby.rpc(2, "round robin", "private")
#		is_host = true
#	if Input.is_key_pressed(KEY_L):
#		pass
#		requestLobbyList.rpc()
#	if Input.is_key_pressed(KEY_K):
#		var keyFile = checkForUserKey()
#		if keyFile:
#			print("YOU ALREADY HAVE AN ACCOUNT")
#			return false
#		if !loggedIn:
#			connectToServer()
#			await multiplayer.connected_to_server
#			if !accountName:
#				closeSession("No username set. set it in the config menu")
#				return false
#			createNewMultiplayerUser.rpc(accountName)
	if Input.is_key_pressed(KEY_J):
		get_node("multiplayer round manager").receiveJoinMatch.rpc(accountName)
