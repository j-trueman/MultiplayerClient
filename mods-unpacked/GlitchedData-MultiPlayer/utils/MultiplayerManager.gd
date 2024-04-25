extends Node

signal player_connected(peerId, playerInfo)
signal player_disconnected(peerId)
signal server_disconnected

var players = {}
var myInfo = {"Name": "Mitch"}
var currentLobbyId = null
var is_host
var keygenUtil
var accountName = null
var userSignature
var userHasCorrectKey
var sessionEnded
var loggedIn = false

func _ready():
	multiplayer.peer_connected.connect(_onPlayerConnected)
	multiplayer.peer_disconnected.connect(_onPlayerDisconnected)
	multiplayer.connected_to_server.connect(_onConnectedOk)
	multiplayer.connection_failed.connect(_onConnectionFail)
	multiplayer.server_disconnected.connect(_onServerDisconnected)
	
	accountName = getUsernameFromFile()
	connectToServer()
	await multiplayer.connected_to_server
	print("\nSUCCESSFULLY CONNECTED TO SERVER. ATTEMPTING LOGIN")
	#doLoginStuff()

func connectToServer():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client("localhost", 2244)
	if error:
		print("ERROR: %s" % error)
		return error
#	await multiplayer.connected_to_server
	multiplayer.multiplayer_peer = peer

func doLoginStuff():
	var keyFile = checkForUserKey()
	if !keyFile:
		closeSession("No user key detected")
		return false
	if accountName == null:
		closeSession("No username set. set it in the config menu")
		return false
	verifyUserCreds.rpc(accountName, keyFile.save_to_string())

func checkForUserKey():
	var keyFile = CryptoKey.new()
	var error = keyFile.load("res://privatekey.key")
	if error:
		return false
	return keyFile

func getUsernameFromFile():
	var f = FileAccess.open("res://mpuser.txt", FileAccess.READ)
	if !f:
		return null
	var line = f.get_line()
	f.close()
	print(line)
	return line

@rpc("authority")
func notifySuccessfulLogin():
	print("SUCCESSFULLY LOGGED IN AS %s" % accountName)
	loggedIn = true

@rpc("authority")
func closeSession(reason):
	if currentLobbyId != null:
		closeLobby.rpc(currentLobbyId)
		currentLobbyId = null
	multiplayer.multiplayer_peer = null
	sessionEnded = true
	print("MULTIPLAYER SESSION TERMINATED: '%s'" % reason)

func removeMultiplayerPeer():
	multiplayer.multiplayer_peer = null

func _onPlayerConnected(id):
	registerPlayer.rpc_id(id, myInfo)

@rpc("any_peer", "reliable")
func registerPlayer(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _onPlayerDisconnected(id):
	if is_host:
		closeLobby.rpc(id)
	player_disconnected.emit(id)

func _onConnectedOk():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = myInfo
	player_connected.emit(peer_id, myInfo)

func _onConnectionFail():
	multiplayer.multiplayer_peer = null

func _onServerDisconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

@rpc("any_peer")
func recieveLobbyList(lobby_list):
	print("PUBLIC_LOBBIES:\n")
	for lobby in lobby_list:
		print("%s" % lobby)
		for info in lobby_list[lobby]:
			print("\t%s - %s" % [info, lobby_list[lobby][info]])
		print("")

@rpc("any_peer")
func recieve_lobby_id(lobby_id):
	currentLobbyId = lobby_id

@rpc("any_peer")
func recieveUserCreationStatus(return_value: bool): 
	if return_value == false:
		print("USER ALREADY EXISTS")
	else:
		print("CREATED USER SUCCESSFULLY")

@rpc("any_peer") 
func requestSenderUsername():
	recieveSenderUsername.rpc(accountName)
	
@rpc("authority")
func recieveUserKey(keyString):
	var keyFile = CryptoKey.new()
	keyFile.load_from_string(keyString)
	keyFile.save("res://privatekey.key")
	doLoginStuff()

# GHOST FUNCTIONS
@rpc("any_peer") func closeLobby(): pass
@rpc("any_peer", "reliable") func create_lobby(): pass
@rpc("any_peer") func requestLobbyList(): pass
@rpc("any_peer", "reliable") func createNewMultiplayerUser(username: String, signature : PackedByteArray) : pass
@rpc("any_peer") func verifyUserCreds(username: String, key): pass
@rpc("any_peer") func recieveSenderUsername(username): pass

# DEBUG INPUTS
func _input(ev):
	if Input.is_key_pressed(KEY_C):
		create_lobby.rpc(2, "round robin", "public")
		is_host = true
	if Input.is_key_pressed(KEY_X):
		if currentLobbyId == null:
			print("YOU ARE NOT IN A LOBBY")
			return false
		closeLobby.rpc(currentLobbyId)
		currentLobbyId = null
	if Input.is_key_pressed(KEY_V):
		create_lobby.rpc(2, "round robin", "private")
		is_host = true
	if Input.is_key_pressed(KEY_L):
		requestLobbyList.rpc()
	if Input.is_key_pressed(KEY_K):
		var keyFile = checkForUserKey()
		if keyFile:
			print("YOU ALREADY HAVE AN ACCOUNT")
			return false
		if !loggedIn:
			connectToServer()
			await multiplayer.connected_to_server
			if !accountName:
				closeSession("No username set. set it in the config menu")
				return false
			createNewMultiplayerUser.rpc(accountName)
	if Input.is_key_pressed(KEY_J):
		get_node("multiplayer round manager").receiveJoinMatch.rpc(myInfo["Name"])
