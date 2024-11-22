extends "res://scripts/RoundManager.gd"

const RoundBatch = preload("res://scripts/RoundBatch.gd")
var currentRoundIdx = 0
var manager
var resetManager
var playerTurn
var currentPlayerTurn
var gotLoadInfo
var score = 0

signal setLoadInfo

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/MultiplayerRoundManager")
	resetManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/reset manager")
	manager.loadInfo.connect(loadInfo)
	manager.resetFlags()
	GlobalVariables.get_current_scene_node().get_node("standalone managers/endless mode").SetupEndless()
	playerData.hasSignedWaiver = true
	super()
	roundArray = []

func EndMainBatch():
	#ADD TO BATCH INDEX
	ignoring = true
	playerData.currentBatchIndex += 1
	if playerData.currentBatchIndex == 3: score *= 2
	#PLAY WINNING SHIT
	await get_tree().create_timer(.8, false).timeout
	if (score > 1): 
		healthCounter.speaker_truedeath.stop()
		healthCounter.DisableCounter()
		defibCutter.BlipError_Both()
		if (endless): musicManager.EndTrack()
		await get_tree().create_timer(.4, false).timeout
		camera.BeginLerp("enemy")
		await get_tree().create_timer(.7, false).timeout
		brief.MainRoutine()
		return
	elif (score < -1):
		# GET SCREWED ENDING
		defibCutter.BlipError_Both()
		await get_tree().create_timer(.8, false).timeout
		await(shellLoader.DealerHandsGrabShotgun())
		await get_tree().create_timer(.2, false).timeout
		shellLoader.animator_shotgun.play("grab shotgun_pointing enemy")
		await get_tree().create_timer(.45, false).timeout
		shellLoader.speaker_loadShell.play()
		shellLoader.animator_dealerHandRight.play("load single shell")
		await get_tree().create_timer(.32, false).timeout
		shellLoader.animator_dealerHandRight.play("RESET")
		dealerAI.Speaker_HandCrack()
		await get_tree().create_timer(.42, false).timeout
		shellLoader.animator_shotgun.play("enemy rack shotgun start")
		manager.receiveActionReady.rpc()
		await manager.smartAwait("action ready")
		dealerAI.animator_shotgun.play("enemy shoot player")
		manager.receiveActionReady.rpc()
		await manager.smartAwait("action ready")
		dealerAI.shotgunShooting.PlayShootingSound_New("live")
		await get_tree().create_timer(.08, false).timeout
		death.viewblocker.visible = true
		death.DisableSpeakers()
		await get_tree().create_timer(.5, false).timeout
		resetManager.Reset()
		return
	healthCounter.DisableCounter()
	speaker_roundShutDown.play()
	await get_tree().create_timer(1, false).timeout
	speaker_winner.play()
	ui_winner.visible = true
	itemManager.newBatchHasBegun = true
	await get_tree().create_timer(2.33, false).timeout
	speaker_winner.stop()
	musicManager.EndTrack()
	for i in range(death.speakersToDisable.size()):
		death.speakersToDisable[i].SnapVolume(true)
	speaker_roundShutDown.play()
	ui_winner.visible = false
	#REGROW BARREL IF MISSING
	if (barrelSawedOff):
		await get_tree().create_timer(.6, false).timeout
		await(segmentManager.GrowBarrel())
	#MAIN BATCH LOOP
	MainBatchSetup(false)
	if (!dealerAtTable): 
		if (!dealerCuffed): animator_dealerHands.play("dealer hands on table")
		else: animator_dealerHands.play("dealer hands on table cuffed")
		animator_dealer.play("dealer return to table")
	for i in range(ejectManagers.size()):
		ejectManagers[i].FadeOutShell()
	#TRACK MANAGER
	await get_tree().create_timer(2, false).timeout
	musicManager.LoadTrack_FadeIn()

func MainBatchSetup(dealerEnterAtStart : bool):
	itemManager.itemsOnTable = [["","","","","","","",""],
					["","","","","","","",""]]
	manager.receivePlayerInfo.rpc()
	manager.receiveLoadInfo.rpc()
	gotLoadInfo = false
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	super(dealerEnterAtStart)

func OutOfHealth(who : String):
	if who == "player":
		score -= 1
		healthCounter.ui_playerwin.text = tr("PLAYERWIN") % [manager.opponent]
	else:
		score += 1
		healthCounter.ui_playerwin.text = tr("PLAYERWIN") % [playerData.playername]
	await get_tree().create_timer(1, false).timeout
	EndMainBatch()

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
	emit_signal("setLoadInfo")

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
	if (manager.players[currentPlayerTurn] == multiplayer.get_unique_id()):
		camera.BeginLerp("home")
		#ALLOW INTERACTION
		playerCurrentTurnItemArray = []
		await get_tree().create_timer(.6, false).timeout
		manager.receiveActionReady.rpc()
		await manager.smartAwait("action ready")
		perm.SetStackInvalidIndicators()
		cursor.SetCursor(true, true)
		perm.SetIndicators(true)
		perm.SetInteractionPermissions(true)
		SetupDeskUI()
		playerTurn = true
	else:
		await get_tree().create_timer(0.641, false).timeout
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
			await get_tree().create_timer(0.5, false).timeout
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
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	perm.SetStackInvalidIndicators()
	cursor.SetCursor(true, true)
	perm.SetIndicators(true)
	perm.SetInteractionPermissions(true)
	SetupDeskUI()
	playerTurn = true

func StartRound(gettingNext : bool):
	if gotLoadInfo:
		manager.receiveLoadInfo.rpc()
		await setLoadInfo
	gotLoadInfo = true
	if (gettingNext): currentRound += 1
	else:
		dealerAI.dealermesh_crushed.set_layer_mask_value(1, false)
		dealerAI.dealermesh_normal.set_layer_mask_value(1, true)
		dealerAI.swapped = false
	#USINGITEMS: SETUP ITEM GRIDS IF ROUND CLASS HAS SETUP ITEM GRIDS ENABLED
	#UNCUFF BOTH PARTIES BEFORE ITEM DISTRIBUTION
	await (handcuffs.RemoveAllCuffsRoutine())
	#FINAL SHOWDOWN DIALOGUE
	if (playerData.currentBatchIndex == 2 && !defibCutterReady && !endless):
		shellLoader.dialogue.dealerLowPitched = true
		camera.BeginLerp("enemy") 
		await get_tree().create_timer(.6, false).timeout
		#var origdelay = shellLoader.dialogue.incrementDelay
		#shellLoader.dialogue.incrementDelay = .1
		if (!playerData.cutterDialogueRead):
			shellLoader.dialogue.scaling = true
			shellLoader.dialogue.ShowText_Forever(tr("FINAL SHOW1"))
			await get_tree().create_timer(4, false).timeout
			shellLoader.dialogue.scaling = true
			shellLoader.dialogue.ShowText_Forever(tr("FINAL SHOW2"))
			await get_tree().create_timer(4, false).timeout
			shellLoader.dialogue.scaling = true
			shellLoader.dialogue.ShowText_Forever(tr("FINAL SHOW3"))
			await get_tree().create_timer(4.8, false).timeout
			shellLoader.dialogue.scaling = false
			shellLoader.dialogue.HideText()
			playerData.cutterDialogueRead = true
		else:
			shellLoader.dialogue.ShowText_Forever(tr("BETTER NOT"))
			await get_tree().create_timer(3, false).timeout
			shellLoader.dialogue.HideText()
		await(deficutter.InitialSetup())
		defibCutterReady = true
		trueDeathActive = true
		#await get_tree().create_timer(100, false).timeout
	#USINGITEMS: SHARE ITEMS TO PLAYERS HERE
	if (roundArray[currentRound].usingItems):
		itemManager.BeginItemGrabbing()
		return
	shellSpawner.MainShellRoutine()
	pass
