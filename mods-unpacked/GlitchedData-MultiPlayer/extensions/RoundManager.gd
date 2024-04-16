extends "res://scripts/RoundManager.gd"

const RoundBatch = preload("res://scripts/RoundBatch.gd")
var currentRoundIdx = 0
var manager

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	manager.loadInfo.connect(loadInfo)

	super()
	roundArray = []
	
func MainBatchSetup(dealerEnterAtStart : bool):
	manager.receiveLoadInfo.rpc()
	super(dealerEnterAtStart)

func SetupRoundArray():
	manager.smartAwait("load info")
	

func loadInfo(roundIdx, loadIdx, currentPlayerTurn, healthPlayers, totalShells, liveCount):
	if roundIdx > currentRoundIdx:
		roundArray = []
		currentRoundIdx = roundIdx
	var firstLoad = true if loadIdx == 0 else false

	var load = RoundClass.new()
	load.hasIntroductoryText = false
	load.isFirstRound = firstLoad
	load.startingHealth = healthPlayers
	load.amountBlank = totalShells - liveCount
	load.amountLive = liveCount
	load.usingItems = true
	load.showingIndicator = firstLoad
	load.indicatorNumber = roundIdx + 1
	load.bootingUpCounter = firstLoad
	load.shufflingArray = true
	load.insertingInRandomOrder = true
	load.numberOfItemsToGrab = 1
	load.hasIntro2 = false

	roundArray.append(load)