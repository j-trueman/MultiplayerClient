extends Node

signal loadInfo(roundIdx, loadIdx, currentPlayerTurn, healthPlayers, totalShells, liveCount)
signal items(itemsForPlayers)
signal actionValidation(action, result)
signal timeoutAdrenaline

@rpc("any_peer")
func receiveJoinMatch(playerName): pass
	
@rpc("any_peer")
func sendJoinMatch(success): pass

@rpc("any_peer")
func receiveLoadInfo(): pass

var loadInfo_flag = false
@rpc("any_peer")
func sendLoadInfo(roundIdx, loadIdx, currentPlayerTurn, healthPlayers, totalShells, liveCount):
	emit_signal("loadInfo", roundIdx, loadIdx, currentPlayerTurn, healthPlayers, totalShells, liveCount)
	loadInfo_flag = true

@rpc("any_peer")
func receiveItems(): pass

var items_flag = false
@rpc("any_peer")
func sendItems(itemsForPlayers):
	emit_signal("items", itemsForPlayers)
	items_flag = true

@rpc("any_peer")
func recieveActionValidation(action): pass

var actionValidation_flag = false
@rpc("any_peer")
func sendActionValidation(action, result):
	emit_signal("actionValidation", action, result)
	actionValidation_flag = true

@rpc("any_peer")
func sendTimeoutAdrenaline():
	emit_signal("timeoutAdrenaline")

func smartAwait(method):
	match method:
		"load info":
			if not loadInfo_flag:
				await loadInfo
			loadInfo_flag = false
		"items":
			if not items_flag:
				await items
			items_flag = false
		"action validation":
			if not actionValidation_flag:
				await actionValidation
			actionValidation_flag = false
