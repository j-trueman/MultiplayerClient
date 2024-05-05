extends "res://scripts/RoundManager.gd"

const RoundBatch = preload("res://scripts/RoundBatch.gd")
var currentRoundIdx = 0
var manager
var playerTurn
var currentPlayerTurn

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	manager.loadInfo.connect(loadInfo)

	super()
	roundArray = []
	
func MainBatchSetup(dealerEnterAtStart : bool):
	manager.receivePlayerInfo.rpc()
	manager.receiveLoadInfo.rpc()
	super(dealerEnterAtStart)

func SetupRoundArray():
	await manager.smartAwait("load info")
	

func loadInfo(roundIdx, loadIdx, currentPlayerTurn_var, healthPlayers, totalShells, liveCount):
	if roundIdx > currentRoundIdx:
		roundArray = []
		currentRoundIdx = roundIdx
	var firstLoad = true if loadIdx == 0 else false

	currentPlayerTurn = currentPlayerTurn_var

	var load = RoundClass.new()
	load.hasIntroductoryText = false
	load.isFirstRound = firstLoad
	load.startingHealth = healthPlayers[0]
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

func LoadShells():
	camera.BeginLerp("enemy")
	if (!shellLoadingSpedUp): await get_tree().create_timer(.8, false).timeout
	await(shellLoader.DealerHandsGrabShotgun())
	await get_tree().create_timer(.2, false).timeout
	shellLoader.animator_shotgun.play("grab shotgun_pointing enemy")
	await get_tree().create_timer(.45, false).timeout
	if (playerData.numberOfDialogueRead < 3):	
		if (shellLoader.diaindex == shellLoader.loadingDialogues.size()):
			shellLoader.diaindex = 0
		var stringshow
		if (shellLoader.diaindex == 0): stringshow = tr("SHELL INSERT1")
		if (shellLoader.diaindex == 1): stringshow = tr("SHELL INSERT2")
		shellLoader.dialogue.ShowText_ForDuration(stringshow, 3)
		shellLoader.diaindex += 1
		await get_tree().create_timer(3, false).timeout
		playerData.numberOfDialogueRead += 1
	var numberOfShells = roundArray[currentRound].amountBlank + roundArray[currentRound].amountLive
	for i in range(numberOfShells):
		shellLoader.speaker_loadShell.play()
		shellLoader.animator_dealerHandRight.play("load single shell")
		if(shellLoadingSpedUp): await get_tree().create_timer(.17, false).timeout
		else: await get_tree().create_timer(.32, false).timeout
		pass
	shellLoader.animator_dealerHandRight.play("RESET")
	dealerAI.Speaker_HandCrack()
	if (shellLoadingSpedUp): await get_tree().create_timer(.17, false).timeout
	else: await get_tree().create_timer(.42, false).timeout
	#INTRODUCTION DIALOGUE
	if (roundArray[currentRound].hasIntroductoryText):
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[0])
		await get_tree().create_timer(1.9, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[1])
		await get_tree().create_timer(3, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[2])
		await get_tree().create_timer(3, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[3])
		await get_tree().create_timer(3, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[4])
		await get_tree().create_timer(3, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[5])
		await get_tree().create_timer(3.7, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[6])
		await get_tree().create_timer(3.7, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[7])
		await get_tree().create_timer(3.7, false).timeout
		shellLoader.dialogue.ShowText_Forever(shellLoader.introductionDialogues[8])
		await get_tree().create_timer(2.5, false).timeout
		playerData.hasReadIntroduction = true
		shellLoader.dialogue.HideText()
	#RACK SHOTGUN, PLACE ON TABLE
	#shellLoader.speaker_rackShotgun.play()
	shellLoader.animator_shotgun.play("enemy rack shotgun start")
	await get_tree().create_timer(.8, false).timeout
	shellLoader.animator_shotgun.play("enemy put down shotgun")
	shellLoader.DealerHandsDropShotgun()
	if (manager.players[currentPlayerTurn].values()[0] == manager.get_parent().myInfo["Name"]):
		camera.BeginLerp("home")
		#ALLOW INTERACTION
		playerCurrentTurnItemArray = []
		await get_tree().create_timer(.6, false).timeout
		perm.SetStackInvalidIndicators()
		cursor.SetCursor(true, true)
		perm.SetIndicators(true)
		perm.SetInteractionPermissions(true)
		SetupDeskUI()
		playerTurn = true
	else:
		EndTurn(false)

func EndTurn(playerCanGoAgain : bool):
	#USINGITEMS: ASSIGN PLAYER CAN GO AGAIN FROM ITEMS HERE
	#USINGITEMS: MAKE SHOTGUN GROW NEW BARREL
	#var isOutOfHealth = CheckIfOutOfHealth()
	#if (isOutOfHealth): return
	if (barrelSawedOff):
		await get_tree().create_timer(.6, false).timeout
		if (waitingForHealthCheck2): await get_tree().create_timer(2, false).timeout
		waitingForHealthCheck2 = false
		await(segmentManager.GrowBarrel())
	if (shellSpawner.sequenceArray.size() != 0):
		#PLAYER TURN
		if (playerCanGoAgain):
			BeginPlayerTurn()
		else:
			#DEALER TURN
			if (!dealerCuffed):
				playerTurn = false
				dealerAI.BeginDealerTurn()
			else:
				if (waitingForReturn):
					await get_tree().create_timer(1.4, false).timeout
					waitingForReturn = false
				if (waitingForHealthCheck): 
					await get_tree().create_timer(1.8, false).timeout
					waitingForHealthCheck = false
				dealerAI.DealerCheckHandCuffs()
	else:
		#SHOTGUN IS EMPTY. NEXT ROUND
		if (requestedWireCut):
			await(defibCutter.CutWire(wireToCut)) 
		if (!ignoring): 
			StartRound(true)

func BeginPlayerTurn():
	if (playerCuffed):
		var returning = false
		if (playerAboutToBreakFree == false):
			handcuffs.CheckPlayerHandCuffs(false)
			await get_tree().create_timer(1.4, false).timeout
			camera.BeginLerp("enemy")
			dealerAI.BeginDealerTurn()
			returning = true
			playerAboutToBreakFree = true
		else:
			handcuffs.BreakPlayerHandCuffs(false)
			await get_tree().create_timer(1.4, false).timeout
			camera.BeginLerp("home")
			playerCuffed = false
			playerAboutToBreakFree = false
			returning = false
		if (returning): return
	if (requestedWireCut):
		await(defibCutter.CutWire(wireToCut))
	await get_tree().create_timer(.6, false).timeout
	playerCurrentTurnItemArray = []
	perm.SetStackInvalidIndicators()
	cursor.SetCursor(true, true)
	perm.SetIndicators(true)
	perm.SetInteractionPermissions(true)
	SetupDeskUI()
	playerTurn = true

func StartRound(gettingNext : bool):
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	super(gettingNext)