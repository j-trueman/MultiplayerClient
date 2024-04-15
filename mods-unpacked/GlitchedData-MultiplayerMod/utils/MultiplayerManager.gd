extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

var players = {}
var my_info = {"Name": "GlitchedData64"}
var players_loaded
var current_lobby
var is_host
var keygenUtil
var accountName = "jeremy"
var userSignature
var keyFile = CryptoKey.new()
var userHasCorrectKey
var sessionEnded
var loggedIn

func _ready():
#	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	keygenUtil = get_tree().root.get_node("KeygenUtil")
	connectToServer()
	await multiplayer.connected_to_server
	print("SUCCESSFULLY CONNECTED TO SERVER. ATTEMPTING LOGIN")	
	doLoginStuff()

func connectToServer():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client("localhost", 2244)
	if error:
		print("ERROR: %s" % error)
		return error
#	await multiplayer.connected_to_server
	multiplayer.multiplayer_peer = peer

@rpc("authority")
func closeSession(reason):
	multiplayer.multiplayer_peer = null
	sessionEnded = true
	print("MULTIPLAYER SESSION TERMINATED: '%s'" % reason)

func doLoginStuff():
	var userKeyExists = checkForUserKey()
	if !userKeyExists:
		print("NO USER KEY DETECTED. PLEASE CREATE AN ACCOUNT IN THE CONFIG MENU.")
		closeSession("No user key detected")
		return false
	verifyUserCreds.rpc(accountName, keyFile.save_to_string())

func checkForUserKey():
	var error = keyFile.load("user://privatekey.key")
	if error:
		return false
	return true

@rpc("authority")
func notifySuccessfulLogin():
	print("SUCCESSFULLY LOGGED IN AS %s" % accountName)
	loggedIn = true

#func JoinGame(address = ""):
#	if address.is_empty():
#		address = "localhost"
#	var peer = ENetMultiplayerPeer.new()
#	var error = peer.create_client(address, 2244)
#	if error:
#		return error
#	multiplayer.multiplayer_peer = peer
#	print("INITIAL CONNECTION")

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null

#func _on_player_connected(id):
#	_register_player.rpc_id(id, my_info)

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id):
	if is_host:
		close_lobby.rpc(id)
	player_disconnected.emit(id)

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = my_info
	player_connected.emit(peer_id, my_info)

func _on_connected_fail():
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

@rpc("any_peer")
func recieve_lobby_list(lobby_list):
	print("PUBLIC_LOBBIES:\n")
	for lobby in lobby_list:
		print("%s" % lobby)
		for info in lobby_list[lobby]:
			print("\t%s - %s" % [info, lobby_list[lobby][info]])
		print("")

@rpc("any_peer")
func recieve_lobby_id(lobby_id):
	current_lobby = lobby_id

@rpc("any_peer")
func user_creation_status(return_value: bool): 
	if return_value == false:
		print("USER ALREADY EXISTS")
	else:
		print("CREATED USER SUCCESSFULLY")


# GHOST FUNCTIONS
@rpc("any_peer") func close_lobby(): pass
@rpc("any_peer", "reliable") func create_lobby(): pass
@rpc("any_peer") func request_lobby_list(): pass
@rpc("any_peer", "reliable") func create_new_multiplayer_user(username: String, signature : PackedByteArray) : pass
@rpc("any_peer") func verifyUserCreds(username: String, keyFile : Resource): pass

# DEBUG INPUTS
func _input(ev):
	if Input.is_key_pressed(KEY_C):
		create_lobby.rpc(2, "round robin", "public")
		is_host = true
	if Input.is_key_pressed(KEY_V):
		create_lobby.rpc(2, "round robin", "private")
		is_host = true
	if Input.is_key_pressed(KEY_L):
		request_lobby_list.rpc()
	if Input.is_key_pressed(KEY_K):
		var signature = keygenUtil.KeyGen()
		if !signature:
			print("YOU ALREADY HAVE AN ACCOUNT")
			return false
		if !loggedIn:
			connectToServer()
			await multiplayer.connected_to_server
			create_new_multiplayer_user.rpc(accountName, signature)
