extends Node

signal loadInfo(roundIdx, loadIdx, currentPlayerTurn, healthPlayers, totalShells, liveCount)
signal items(itemsForPlayers)
signal actionValidation(action, result)
signal timeoutAdrenaline
signal actionReady
signal itemsOnTable_signal(itemsOnTable)

var players
var opponent

@rpc("any_peer")
func receiveJoinMatch(playerName): pass
	
@rpc("any_peer")
func sendJoinMatch(success): pass

@rpc("any_peer")
func receivePlayerInfo(): pass

@rpc("any_peer")
func sendPlayerInfo(players_var):
	players = players_var
	var firstPlayer = players[0].values()[0]
	opponent = players[1].values()[0] if firstPlayer == get_parent().myInfo["Name"] else firstPlayer
	GlobalVariables.get_current_scene_node().get_node(tabletop parent/main tabletop/health counter/health counter ui parent/health UI_dealer side/text dealer").text = opponent

@rpc("any_peer")
func sendTimeoutAdrenaline():
	emit_signal("timeoutAdrenaline")

@rpc("any_peer")
func receiveLoadInfo(): pass

var loadInfo_flag = false
var loadInfo_smart = false
@rpc("any_peer")
func sendLoadInfo(roundIdx, loadIdx, currentPlayerTurn, healthPlayers, totalShells, liveCount):
	emit_signal("loadInfo", roundIdx, loadIdx, currentPlayerTurn, healthPlayers, totalShells, liveCount)
	if not loadInfo_smart: loadInfo_flag = true
	loadInfo_smart = false

@rpc("any_peer")
func receiveItems(): pass

var items_flag = false
var items_smart = false
@rpc("any_peer")
func sendItems(itemsForPlayers):
	emit_signal("items", itemsForPlayers)
	if not items_smart: items_flag = true
	items_smart = false

@rpc("any_peer")
func receiveActionValidation(action): pass

var actionValidation_flag = false
var actionValidation_smart = false
@rpc("any_peer")
func sendActionValidation(action, result):
	emit_signal("actionValidation", action, result)
	if not actionValidation_smart: actionValidation_flag = true
	actionValidation_smart = false

@rpc("any_peer")
func receiveActionReady(): pass

var actionReady_flag = false
var actionReady_smart = false
@rpc("any_peer")
func sendActionReady():
	emit_signal("actionReady")
	if not actionReady_smart: actionReady_flag = true
	actionReady_smart = false

@rpc("any_peer")
func receiveItemsOnTable(itemTableIdxArray): pass

@rpc("any_peer")
func sendItemsOnTable(itemsOnTable):
	emit_signal("itemsOnTable_signal", itemsOnTable)

func smartAwait(method):
	match method:
		"load info":
			if not loadInfo_flag:
				loadInfo_smart = true
				await loadInfo
			loadInfo_flag = false
		"items":
			if not items_flag:
				items_smart = true
				await items
			items_flag = false
		"action validation":
			if not actionValidation_flag:
				actionValidation_smart = true
				await actionValidation
			actionValidation_flag = false
		"action ready":
			if not actionReady_flag:
				actionReady_smart = true
				await actionReady
			actionReady_flag = false