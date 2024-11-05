extends Node

const MP_IngameLobbyUI = preload("res://multiplayer/scripts/global scripts/MP_IngameLobbyUI.gd")


# Singleplayer

var prefix = "BRML Steam: "

enum {
	LEADERBOARD_DATA_REQUEST_FRIENDS,
	LEADERBOARD_DATA_REQUEST_GLOBAL,
	LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER
}

signal leaderboard_find_result(var1, var2)
signal leaderboard_score_uploaded(var1, var2, var3)
signal leaderboard_scores_downloaded(var1, var2, var3)

func clearAchievement(var1):
	print(prefix + "Cleared achievement")
	return false

func downloadLeaderboardEntries(var1, var2, var3):
	print(prefix + "Downloaded leaderboard entries")

func findLeaderboard(var1):
	print(prefix + "Found leaderboard")

func getLeaderboardEntryCount(var1):
	print(prefix + "Got leaderboard entry count")
	return 0

func setAchievement(var1):
	print(prefix + "Set achievement")

func setLeaderboardDetailsMax(var1):
	print(prefix + "Set leaderboard details max")
	return 0

func storeStats():
	print(prefix + "Stored stats")

func uploadLeaderboardScore(var1, var2, var3, var4):
	print(prefix + "Uploaded leaderboard score")

# Multiplayer

var url = "localhost"
var port = 2096
var username = "PLAYER"
var configPath = "res://BRML.cfg"
var loggedIn = false
var steamID
var players = []
var packets = []
var configFile

func _ready():
	multiplayer.connected_to_server.connect(_on_server_connected)

func _on_server_connected():
	appendUsername.rpc(username)

@rpc("any_peer", "reliable")
func receivePacket(data):
	packets.append(data)

# VARIABLES
# MP_LobbyManager.gd
const LOBBY_TYPE_FRIENDS_ONLY = 1

enum {
	CHAT_ROOM_ENTER_RESPONSE_NONE,	# Doesn't exist, for 0 value
	CHAT_ROOM_ENTER_RESPONSE_SUCCESS,
	CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST,
	CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED,
	CHAT_ROOM_ENTER_RESPONSE_FULL,
	CHAT_ROOM_ENTER_RESPONSE_ERROR,
	CHAT_ROOM_ENTER_RESPONSE_BANNED,
	CHAT_ROOM_ENTER_RESPONSE_LIMITED,
	CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED,
	CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN,
	CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU,
	CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER
}

const CHAT_MEMBER_STATE_CHANGE_ENTERED = 1
const CHAT_MEMBER_STATE_CHANGE_LEFT = 2
const CHAT_MEMBER_STATE_CHANGE_KICKED = 8
const CHAT_MEMBER_STATE_CHANGE_BANNED = 16

# MP_PacketManager.gd
const P2P_SEND_RELIABLE = 2

# SIGNALS
# MP_LobbyManager.gd
signal join_requested(this_lobby_id, friend_id)
@rpc("any_peer", "reliable")
func receiveJoinRequest(this_lobby_id, friend_id):
	join_requested.emit(this_lobby_id, friend_id)

signal lobby_chat_update(this_lobby_id, change_id, making_change_id, chat_state)
@rpc("any_peer", "reliable")
func receiveLobbyChat(this_lobby_id, change_id, making_change_id, chat_state, data):
	players = data
	lobby_chat_update.emit(this_lobby_id, change_id, making_change_id, chat_state)
	
signal lobby_created(connect, this_lobby_id)
@rpc("any_peer", "reliable")
func receiveLobbyCreated(connect, this_lobby_id):
	lobby_created.emit(connect, this_lobby_id)

signal lobby_joined(this_lobby_id, _permissions, _locked, response)
@rpc("any_peer", "reliable")
func receiveLobbyJoined(this_lobby_id, _permissions, _locked, response, data):
	players = data
	lobby_joined.emit(this_lobby_id, _permissions, _locked, response)

signal persona_state_change(this_steam_id, _flag)
@rpc("any_peer", "reliable")
func receivePersonaStateChange(this_steam_id, _flag):
	persona_state_change.emit(this_steam_id, _flag)

# MP_PacketManager.gd
signal p2p_session_request(remote_id)
signal p2p_session_connect_fail(steam_id, session_error)

#MP_IngameLobbyUI.gd
signal avatar_loaded(user_id, avatar_size, avatar_buffer)


# METHODS
#Steam.gd
func loggedOn():
	return loggedIn

func getSteamID():
	return steamID

func getPersonaName():
	return str(steamID)

func run_callbacks(): pass

func steamInit(var1 = null):
	if configFile == null:
		var configFile = ConfigFile.new()
		if configFile.load(configPath) != OK or configFile.get_sections().is_empty():
			configFile.set_value("multiplayer", "url", url)
			configFile.set_value("multiplayer", "username", username)
			configFile.save(configPath)
		else:
			url = configFile.get_value("multiplayer", "url")
			username = configFile.get_value("multiplayer", "username")

	var vibeCheck = true
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(url, port)
	if error:
		vibeCheck = false
	else:
		multiplayer.set_multiplayer_peer(peer)
	loggedIn = vibeCheck
	steamID = multiplayer.get_unique_id()
	GlobalSteam.STEAM_ID = steamID
	return {"status": 1, "verbal": "Steamworks active"} if loggedIn \
		else {"status": 20, "verbal": "Steam not running"}

#MP_LobbyManager.gd
func activateGameOverlayInviteDialog(var1):
	pass

func createLobby(lobby_type, max_players):
	createLobbyRPC.rpc()

func setLobbyJoinable(var1, var2):
	pass

func setLobbyData(var1, var2, var3):
	pass

func allowP2PPacketRelay(var1):
	return true

func getFriendPersonaName(id):
	var username = "PLAYER"
	for player in players:
		if player.id == id:
			username = player.username
			break
	return username		

func joinLobby(steam_lobby_id):
	joinLobbyRPC.rpc(steam_lobby_id)

func leaveLobby(steam_lobby_id):
	leaveLobbyRPC.rpc(steam_lobby_id)

func closeP2PSessionWithUser(var1):
	pass

func getNumLobbyMembers(steam_lobby_id):
	return players.size()

func getLobbyMemberByIndex(steam_lobby_id, member):
	var returnVal : int
	if not players.is_empty():
		var player = players.front()
		if players.size() > member:
			player = players[member]
			returnVal = player.id
	return returnVal

func getLobbyOwner(steam_lobby_id):
	return 0 if players.is_empty() else players.front().id

# MP_PacketManager.gd
func getAvailableP2PPacketSize(channel):
	return packets.size()

func sendP2PPacket(steam_id_remote, data, send_type, channel):
	sendP2PPacketRPC.rpc(steam_id_remote, data)

func readP2PPacket(packet_size, channel):
	return packets.pop_front()

func acceptP2PSessionWithUser(var1):
	return true

# MP_IngameLobbyUI.gd
func getPlayerAvatar(var1, var2):
	pass

@rpc("any_peer", "reliable") func createLobbyRPC(): pass
@rpc("any_peer", "reliable") func appendUsername(username): pass
@rpc("any_peer", "reliable") func joinLobbyRPC(steam_lobby_id): pass
@rpc("any_peer", "reliable") func leaveLobbyRPC(steam_lobby_id): pass
@rpc("any_peer", "reliable") func sendP2PPacketRPC(steam_id_remote, data): pass