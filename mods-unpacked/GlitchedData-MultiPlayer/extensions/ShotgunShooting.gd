extends "res://scripts/ShotgunShooting.gd"

var manager
var interaction

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	interaction = GlobalVariables.get_current_scene_node().get_node("standalone managers/interaction manager")

func Shoot(who : String):
	dealerShotTrue = false
	disablingDelayShit = false
	playerCanGoAgain = false
	var playerDied = false
	var dealerShot = false
	ejectionManager_player.FadeOutShell()
	cursorManager.SetCursor(false, false)
	#CAMERA CONTROLS & ANIMATION DEPENDING ON WHO IS SHOT
	match(who):
		"self":
			await get_tree().create_timer(.25, false).timeout
			animator_shotgun.play("player shoot self")
			await get_tree().create_timer(.5, false).timeout
			camera.BeginLerp("enemy")
		"dealer":
			await get_tree().create_timer(.25, false).timeout
			animator_shotgun.play("player shoot dealer")
			await get_tree().create_timer(.5, false).timeout
			camera.BeginLerp("enemy")
	#PLAY CORRECT SOUND. ASSIGN CURRENT ROUND IN CHAMBER
	await get_tree().create_timer(2, false).timeout
	await manager.smartAwait("action validation")
	shellSpawner.sequenceArray[0] = "live" if bool(interaction.result) else "blank"
	var currentRoundInChamber = shellSpawner.sequenceArray[0]
	MainSlowDownRoutine(who, false)
	if (who == "self"): whoshot = "player"
	else: whoshot = "dealer"
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	PlayShootingSound_New(currentRoundInChamber)
	#SHAKE CAMERA
	if (currentRoundInChamber == "live"):
		smoke.SpawnSmoke("barrel")
		cameraShaker.Shake()
	#SUBTRACT HEALTH. ASSIGN PLAYER CAN GO AGAIN. RETURN IF DEAD
	if (currentRoundInChamber == "live" && who == "dealer"): 
		roundManager.health_opponent -= roundManager.currentShotgunDamage
		if (roundManager.health_opponent < 0): roundManager.health_opponent = 0
	if (currentRoundInChamber == "live" && who == "self"): 
		CheckAchievement_why()
		CheckAchievement_style()
		roundManager.waitingForHealthCheck2 = true
		if (shellSpawner.sequenceArray.size() == 1): 
			whatTheFuck = true
		roundManager.waitingForDealerReturn = true
		healthCounter.playerShotSelf = true
		playerDied = true
		roundManager.health_player -= roundManager.currentShotgunDamage
		if (roundManager.health_player < 0): roundManager.health_player = 0
		playerCanGoAgain = false
		healthCounter.checkingPlayer = true
		await(death.Kill("player", false, true))
	if (currentRoundInChamber == "blank" && who == "self"): 
		playerCanGoAgain = true
		CheckAchievement_coinflip()
	if (currentRoundInChamber == "live" && who == "dealer"): 
		playerCanGoAgain = false
		dealerShot = true
		dealerShotTrue = true
		await(death.Kill("dealer", false, false))
	if (playerDied): return
	if (dealerShot): return
	await get_tree().create_timer(.3, false).timeout
	#EJECTING SHELLS
	if (currentRoundInChamber == "blank" && who == "self"):
		animator_shotgun.play("player eject shell")
		await get_tree().create_timer(.85, false).timeout
		camera.BeginLerp("home")
		await get_tree().create_timer(1.35, false).timeout
		FinalizeShooting(playerCanGoAgain, true, false, false)
		return
	if (currentRoundInChamber == "blank" && who == "dealer"): disablingDelayShit = true
	ShootingDealerEjection(currentRoundInChamber, who, false)

func PlayShootingSound_New(currentRoundInChamber):
	if (currentRoundInChamber == "live"):
		CheckIfFinalShot()
		speaker_live.play()
		roundManager.playerData.stat_shotsFired += 1
		animator_muzzleFlash.play("muzzle flash fire")
		animator_muzzleFlash_model.play("fire")
	else: 
		speaker_blank.play()
	pass

func GrabShotgun():
	roundManager.ClearDeskUI(true)
	perm.SetIndicators(false)
	perm.SetInteractionPermissions(false)
	perm.RevertDescriptionUI()
	ShotgunCollider(false)
	animator_shotgun.play("player grab shotgun")
	shotgunshaker.StartShaking()
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	decisionText.SetUI(true)
	btnParent_shootingChoice.visible = true
	if (cursorManager.controller_active): btn_you.grab_focus()
	controller.previousFocus = btn_you
	await get_tree().create_timer(.5, false).timeout