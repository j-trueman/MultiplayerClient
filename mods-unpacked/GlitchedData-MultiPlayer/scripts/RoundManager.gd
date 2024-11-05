extends Node

const Achievement = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/AchievementManager.gd")
const Amounts = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ItemAmounts.gd")
const BriefcaseMachine = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/BriefcaseMachine.gd")
const CameraManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/CameraManager.gd")
const ControllerManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ControllerManager.gd")
const CursorManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/CursorManager.gd")
const DealerIntelligence = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/DealerIntelligence.gd")
const DeathManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/DeathManager.gd")
const DefibCutter = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/DefibCutter.gd")
const GameOverManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/GameOverManager.gd")
const HandcuffManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/HandcuffManager.gd")
const HealthCounter = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/HealthCounter.gd")
const InteractionBranch = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/InteractionBranch.gd")
const ItemManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ItemManager.gd")
const MusicManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/MusicManager.gd")
const PermissionManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/PermissionManager.gd")
const PlayerData = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/PlayerData.gd")
const RoundClass = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/RoundClass.gd")
const SegmentManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/SegmentManager.gd")
const ShellEjectManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ShellEjectManager.gd")
const ShellLoader = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ShellLoader.gd")
const ShellSpawner = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ShellSpawner.gd")
const Signature = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/SignatureManager.gd")
const Statue = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/StatueManager.gd")
const TypingManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/TypingManager.gd")

@export var sign : Signature
@export var brief : BriefcaseMachine
@export var defibCutter : DefibCutter
@export var segmentManager : SegmentManager
@export var handcuffs : HandcuffManager
@export var itemManager : ItemManager
@export var death : DeathManager
@export var playerData : PlayerData
@export var cursor : CursorManager
@export var controller : ControllerManager
@export var perm : PermissionManager
@export var health_player : int
@export var health_opponent : int
@export var batchArray : Array[Node]
@export var roundArray : Array[RoundClass]
@export var shellSpawner : ShellSpawner
@export var shellLoader : ShellLoader
@export var currentRound : int
var mainBatchIndex : int
@export var healthCounter : HealthCounter
@export var dealerAI : DealerIntelligence
@export var typingManager : TypingManager
@export var camera : CameraManager
@export var roundIndicatorPositions : Array[Vector3]
@export var roundIndicatorParent : Node3D
@export var roundIndicator : Node3D
@export var animator_roundIndicator : AnimationPlayer
@export var speaker_roundHum : AudioStreamPlayer3D
@export var speaker_roundShutDown : AudioStreamPlayer3D
@export var speaker_winner : AudioStreamPlayer3D
@export var ui_winner : Node3D
@export var animator_dealer : AnimationPlayer
@export var ejectManagers : Array[ShellEjectManager]
@export var animator_dealerHands : AnimationPlayer
@export var gameover : GameOverManager
@export var musicManager : MusicManager
@export var deficutter : DefibCutter
@export var anim_doubleor : AnimationPlayer
@export var anim_yes : AnimationPlayer
@export var anim_no : AnimationPlayer
@export var intbranch_yes : InteractionBranch
@export var intbranch_no : InteractionBranch
@export var speaker_slot : AudioStreamPlayer2D

var endless = false
var shellLoadingSpedUp = false
var dealerItems : Array[String]
var currentShotgunDamage = 1
var dealerAtTable = false
var dealerHasGreeted = false
var dealerCuffed = false
var playerCuffed = false
var playerAboutToBreakFree = false
var waitingForDealerReturn = false
var barrelSawedOff = false
var defibCutterReady = false
var trueDeathActive = false
var playerCurrentTurnItemArray = []

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/MultiplayerRoundManager")
	resetManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/reset manager")
	manager.loadInfo.connect(loadInfo)
	manager.resetFlags()
	GlobalVariables.get_current_scene_node().get_node("standalone managers/endless mode").SetupEndless()
	playerData.hasSignedWaiver = true
	Engine.time_scale = 1
	HideDealer()
	roundArray = []

func _process(delta):
	LerpScore()
	InitialTimer()

var counting = false
var initial_time = 0
func InitialTimer():
	if (counting): initial_time += get_process_delta_time()

func BeginMainGame():
	MainBatchSetup(true)

func HideDealer():
	animator_dealerHands.play("hide hands")
	animator_dealer.play("hide dealer")

#MAIN BATCH SETUP
var lerping = false
var enteringFromWaiver = false
func MainBatchSetup(dealerEnterAtStart : bool):
	itemManager.itemsOnTable = [["","","","","","","",""],
					["","","","","","","",""]]
	manager.receivePlayerInfo.rpc()
	manager.receiveLoadInfo.rpc()
	gotLoadInfo = false
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	if (!enteringFromWaiver):
		if (lerping): camera.BeginLerp("enemy")
		currentRound = 0
		if (!dealerAtTable && dealerEnterAtStart):
			await get_tree().create_timer(.5, false).timeout
			if (!dealerCuffed): animator_dealerHands.play("dealer hands on table")
			else: animator_dealerHands.play("dealer hands on table cuffed")
			animator_dealer.play("dealer return to table")
			await get_tree().create_timer(2, false).timeout
			var greeting = true
			if (!playerData.hasSignedWaiver):
				shellLoader.dialogue.ShowText_Forever(tr("WAIVER"))
				await get_tree().create_timer(2.3, false).timeout
				shellLoader.dialogue.HideText()
				camera.BeginLerp("home")
				sign.AwaitPickup()
				return
			if (!dealerHasGreeted && greeting):
				var tempstring
				if (!playerData.enteringFromTrueDeath): tempstring = tr("WELCOME")
				else: 
					shellSpawner.dialogue.dealerLowPitched = true
					tempstring = "..."
				if (!playerData.playerEnteringFromDeath):
					shellLoader.dialogue.ShowText_Forever("...")
					await get_tree().create_timer(2.3, false).timeout
					shellLoader.dialogue.HideText()
					dealerHasGreeted = true
				else:
					shellLoader.dialogue.ShowText_Forever(tempstring)
					await get_tree().create_timer(2.3, false).timeout
					shellLoader.dialogue.HideText()
					dealerHasGreeted = true
			dealerAtTable = true
	enteringFromWaiver = false
	playerData.enteringFromTrueDeath = false
	mainBatchIndex = playerData.currentBatchIndex
	healthCounter.DisableCounter()
	SetupRoundArray()
	if (playerData.hasReadIntroduction): roundArray[0].hasIntroductoryText = false
	else: roundArray[0].hasIntroductoryText = true
	if (roundArray[0].showingIndicator): await(RoundIndicator())
	healthCounter.SetupHealth()
	lerping = true
	#await get_tree().create_timer(1.5, false).timeout
	if (!endless): ParseMainGameAmounts()
	StartRound(false)

@export var amounts : Amounts
func ParseMainGameAmounts():
	for res in amounts.array_amounts:
		res.amount_active = res.amount_main

var curhealth = 0
func GenerateRandomBatches():
	for b in batchArray:
		for i in range(b.roundArray.size()):
			b.roundArray[i].startingHealth = randi_range(2, 4)
			curhealth = b.roundArray[i].startingHealth
			
			var total_shells = randi_range(2, 8)
			var amount_live = max(1, total_shells / 2)
			var amount_blank = total_shells - amount_live
			b.roundArray[i].amountBlank = amount_blank
			b.roundArray[i].amountLive = amount_live
			
			b.roundArray[i].numberOfItemsToGrab = randi_range(2, 5)
			b.roundArray[i].usingItems = true
			var flip = randi_range(0, 1)
			if flip == 1: b.roundArray[i].shufflingArray = true

@export var statue : Statue
#SHOW ROUND INDICATOR
func RoundIndicator():
	roundIndicator.visible = false
	#await get_tree().create_timer(1.5, false).timeout
	animator_roundIndicator.play("RESET")
	camera.BeginLerp("health counter")
	await get_tree().create_timer(.8, false).timeout
	statue.CheckStatus()
	var activePos = roundIndicatorPositions[roundArray[0].indicatorNumber]
	roundIndicator.transform.origin = activePos
	roundIndicatorParent.visible = true
	speaker_roundHum.play()
	await get_tree().create_timer(.8, false).timeout
	roundIndicator.visible = true
	brief.ending.endless_roundsbeat += 1
	animator_roundIndicator.play("round blinking")
	await get_tree().create_timer(2, false).timeout
	roundIndicatorParent.visible = false
	speaker_roundHum.stop()
	speaker_roundShutDown.play()
	animator_roundIndicator.play("RESET")
	pass

#MAIN ROUND SETUP AFTER ITEMS HAVE BEEN DISTRIBUTED. RETURN TO HERE FROM ITEM GRABBING INTERACTION
func ReturnFromItemGrabbing():
	shellSpawner.MainShellRoutine()
	pass

func CheckIfOutOfHealth():
	#CHECK IF OUT OF HEALTH
	var outOfHealth_player = health_player == 0
	var outOfHealth_enemy = health_opponent == 0
	var outOfHealth = outOfHealth_player or outOfHealth_enemy
	if (outOfHealth):
		if (outOfHealth_player): OutOfHealth("player")
		if (outOfHealth_enemy):  OutOfHealth("dealer")
		return outOfHealth

var waitingForReturn = false
var waitingForHealthCheck = false
var waitingForHealthCheck2 = false
var requestedWireCut = false
var wireToCut = ""
var wireIsCut_dealer = false
var wireIsCut_player = false

var ignoring = false

func ReturnFromCuffCheck(brokeFree : bool):
	if (brokeFree):
		await get_tree().create_timer(.8, false).timeout
		camera.BeginLerp("enemy")
		dealerAI.BeginDealerTurn()
		pass
	else:
		camera.BeginLerp("home")
		BeginPlayerTurn()
	pass

@export var deskUI_parent : Control
@export var deskUI_shotgun : Control
@export var deskUI_briefcase : Control
@export var deskUI_grids : Array[Control]
func SetupDeskUI():
	deskUI_parent.visible = true
	deskUI_shotgun.visible = true
	if (roundArray[currentRound].usingItems):
		for b in deskUI_grids: b.visible = true
	else: for b in deskUI_grids: b.visible = false
	
	if (cursor.controller_active): deskUI_shotgun.grab_focus()
	controller.previousFocus = deskUI_shotgun

func ClearDeskUI(includingParent : bool):
	if (includingParent): deskUI_parent.visible = false
	deskUI_shotgun.visible = false
	for b in deskUI_grids: b.visible = false
	controller.previousFocus = null
	pass

var doubling = false
var prevscore = 0
var mainscore = 0
var elapsed = 0
var dur = 3
var double_or_nothing_rounds_beat = 0
var double_or_nothing_score = 0
var double_or_nothing_initial_score = 0
var doubled = false

var lerpingscore = false
var startscore
var endscore = 0
@export var ui_score : Label3D
@export var ui_doubleornothing : Label3D
@export var speaker_key : AudioStreamPlayer2D
@export var speaker_show : AudioStreamPlayer2D
@export var speaker_hide : AudioStreamPlayer2D

@export var btnParent_doubleor : Control
@export var btn_yes : Control
func BeginScoreLerp():
	startscore = prevscore
	if (!doubling): 
		double_or_nothing_rounds_beat += 1
		var ten_minutes_seconds = 600
		var ten_minutes_score_loss = 40000
		var score_deduction = initial_time / ten_minutes_seconds * ten_minutes_score_loss	
		endscore = 70000 - int(score_deduction)
		if (endscore < 10): endscore = 10
		prevscore = endscore
		double_or_nothing_score = prevscore
		double_or_nothing_initial_score = prevscore
	else: 
		doubled = true
		endscore = prevscore * 2
		prevscore = endscore
		double_or_nothing_rounds_beat += 1
		double_or_nothing_score = prevscore
	doubling = true
	speaker_slot.play()
	camera.BeginLerp("yes no")
	await get_tree().create_timer(1.1, false).timeout
	ui_score.visible = true
	ui_score.text = str(startscore)
	await get_tree().create_timer(.5, false).timeout
	elapsed = 0
	lerpingscore = true
	await get_tree().create_timer(3.08, false).timeout
	await get_tree().create_timer(.46, false).timeout
	ui_score.visible = false
	ui_doubleornothing.visible = true
	anim_doubleor.play("show")
	speaker_show.play()
	await get_tree().create_timer(.5, false).timeout
	await get_tree().create_timer(1, false).timeout
	cursor.SetCursor(true, true)
	intbranch_no.interactionAllowed = true
	intbranch_yes.interactionAllowed = true
	btnParent_doubleor.visible = true
	if (cursor.controller_active): btn_yes.grab_focus()
	controller.previousFocus = btn_yes
	pass

func RevertDoubleUI():
	btnParent_doubleor.visible = false

@export var ach : Achievement
func Response(rep : bool):
	RevertDoubleUI()
	intbranch_no.interactionAllowed = false
	intbranch_yes.interactionAllowed = false
	cursor.SetCursor(false, false)
	ui_doubleornothing.visible = false
	if (rep): anim_yes.play("press")
	else: anim_no.play("press")
	speaker_key.play()
	await get_tree().create_timer(.4, false).timeout
	anim_doubleor.play("hide")
	speaker_hide.play()
	await get_tree().create_timer(.4, false).timeout
	if (!rep):
		speaker_slot.stop()
		await get_tree().create_timer(.7, false).timeout
		brief.ending.endless_score = endscore
		brief.ending.endless_overwriting = true
		camera.BeginLerp("enemy")
		brief.MainRoutine()
	else:
		speaker_slot.stop()
		await get_tree().create_timer(.7, false).timeout
		#camera.BeginLerp("enemy")
		RestartBatch()
		pass

func LerpScore():
	if (lerpingscore):
		elapsed += get_process_delta_time()
		var c = clampf(elapsed / dur, 0.0, 1.0)
		var score = lerp(startscore, endscore, c)
		ui_score.text = str(int(score))

func RestartBatch():
	playerData.currentBatchIndex = 0
	if (barrelSawedOff):
		await get_tree().create_timer(.6, false).timeout
		await(segmentManager.GrowBarrel())
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

const RoundBatch = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/RoundBatch.gd")
var currentRoundIdx = 0
var manager
var resetManager
var playerTurn
var currentPlayerTurn
var gotLoadInfo
var score = 0

signal setLoadInfo

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
