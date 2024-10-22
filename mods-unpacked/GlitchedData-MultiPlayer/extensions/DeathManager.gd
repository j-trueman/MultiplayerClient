extends "res://scripts/DeathManager.gd"

var multiManager
var manager
var environment
var splatter
var speaker_revive_truedeath : AudioStreamPlayer2D
var lerping = false
var elapsed_time = 0.0
var brightness = 0.0

func _ready():
	multiManager = get_tree().get_root().get_node("MultiplayerManager")
	manager = get_tree().get_root().get_node("MultiplayerManager/MultiplayerRoundManager")
	environment = GlobalVariables.get_current_scene_node().get_node("WorldEnvironment").environment
	splatter = GlobalVariables.get_current_scene_node().get_node("Camera/blood splatter plane")
	
	var file = FileAccess.open("res://mods-unpacked/GlitchedData-MultiPlayer/media/player revive truedeath.mp3", FileAccess.READ)
	var buffer = file.get_buffer(file.get_length())
	var stream = AudioStreamMP3.new()
	stream.data = buffer
	speaker_revive_truedeath = AudioStreamPlayer2D.new()
	speaker_revive_truedeath.volume_db = 5
	speaker_revive_truedeath.stream = stream
	GlobalVariables.get_current_scene_node().get_node("speaker parent").add_child(speaker_revive_truedeath)
	super()

func _process(delta):
	if (lerping):
		elapsed_time += delta
		if elapsed_time > 0.05:
			brightness += 0.01
			elapsed_time = 0.0
		if brightness > 1.49:
			brightness = 1.49
			lerping = false
		environment.adjustment_brightness = brightness

func MainDeathRoutine():
	multiManager.inMatch = false
	super()

func MedicineDeath():
	viewblocker.visible = true
	cam.cam.rotation_degrees = Vector3(cam.cam.rotation_degrees.x, cam.cam.rotation_degrees.y, 0)
	DisableSpeakers()
	if (shotgunShooting.roundManager.health_player > 0):
		await get_tree().create_timer(.4, false).timeout
		speaker_playerDefib.play()
		await get_tree().create_timer(.85, false).timeout
		speaker_heartbeat.play()
		animator_pp.play("revival brightness")
		defibParent.visible = true
		animator_playerDefib.play("RESET")
		viewblocker.visible = false
		filter.BeginPan(filter.lowPassMaxValue, filter.lowPassDefaultValue)
		FadeInSpeakers()
		cameraShaker.Shake()
		await get_tree().create_timer(.6, false).timeout
		animator_playerDefib.play("remove defib device")
		await get_tree().create_timer(.4, false).timeout
		#await(healthCounter.UpdateDisplayRoutine(false, !shotgunShooting.playerCanGoAgain, false))
		defibParent.visible = false
	else:
		await get_tree().create_timer(1, false).timeout
		elapsed_time = 0.0
		brightness = 0.0
		lerping = true
		environment.adjustment_brightness = 0.0
		viewblocker.visible = false
		await get_tree().create_timer(5, false).timeout
		shotgunShooting.roundManager.OutOfHealth("player")

func Kill(who : String, trueDeath : bool, returningShotgun : bool):
	var dealerKilledSelf = false
	shitIsFuckedUp = false
	healthCounter.skipping_careful = true
	match(who):
		"player":
			if (trueDeath):
				pass
			else:
				await get_tree().create_timer(.08, false).timeout
				viewblocker.visible = true
				shotgunShooting.shotgunshaker.StopShaking()
				if (not shotgunShooting.roundManager.playerTurn and shotgunShooting.roundManager.health_player == 0):
					animator_dealerHands.play("RESET")
					shellLoader.DealerHandsDropShotgun()
				if (returningShotgun):
					var addingDelay = false
					ejectManager_player.DeathEjection()
					await get_tree().create_timer(2)
					if (shotgunShooting.roundManager.health_opponent == 1 or shotgunShooting.roundManager.health_player == 1): addingDelay = true
					#if (shellLoader.roundManager.shellSpawner.sequenceArray.size() != 0): shotgunShooting.delaying = true
					if (shotgunShooting.roundManager.health_player == 1): shitIsFuckedUp = true
					if (shotgunShooting.roundManager.health_player != 0): shotgunShooting.FinalizeShooting(shotgunShooting.playerCanGoAgain, true, true, addingDelay)
				DisableSpeakers()
				if (shotgunShooting.roundManager.health_player > 0):
					await get_tree().create_timer(.4, false).timeout
					speaker_playerDefib.play()
					await get_tree().create_timer(.85, false).timeout
					speaker_heartbeat.play()
					animator_pp.play("revival brightness")
					defibParent.visible = true
					animator_playerDefib.play("RESET")
					viewblocker.visible = false
					filter.BeginPan(filter.lowPassMaxValue, filter.lowPassDefaultValue)
					FadeInSpeakers()
					cameraShaker.Shake()
					await get_tree().create_timer(.6, false).timeout
					animator_playerDefib.play("remove defib device")
					await get_tree().create_timer(.4, false).timeout
					await(healthCounter.UpdateDisplayRoutine(false, !shotgunShooting.playerCanGoAgain, false))
					defibParent.visible = false
				else:
					shotgunShooting.roundManager.dealerAtTable = true
					await get_tree().create_timer(1, false).timeout
					dealerAI.dealerHoldingShotgun = false
					animator_shotgun.play("RESET")
					shotgunShooting.shotgunIndicator.Revert()
					shotgunShooting.ShotgunCollider(true)
					healthCounter.DisableCounter()
					speaker_revive_truedeath.play()
					await get_tree().create_timer(1, false).timeout
					splatter.transparency = 0.0
					shotgunShooting.mat_splatter.material_override.set("albedo_texture", shotgunShooting.splatters[3])
					elapsed_time = 0.0
					brightness = 0.0
					lerping = true
					environment.adjustment_brightness = 0.0
					viewblocker.visible = false
					dealerAI.roundManager.musicManager.EndTrack()
					await get_tree().create_timer(3.7, false).timeout
					FadeInSpeakers()
					shotgunShooting.anim_splatter.play("fade out")
					shotgunShooting.roundManager.OutOfHealth("player")
		"dealer":
			if (trueDeath):
				pass
			else:
				if (returningShotgun):
					dealerKilledSelf = true
					shotgunShooting.MainSlowDownRoutine("dealer", true)
					animator_shotgun.play("enemy return shotgun self")
					dealerAI.dealerHoldingShotgun = false	
					ejectManager_dealer.DeathEjection()
				animator_dealer.play("dealer fly away")
				animator_dealerHands.play("hide hands")
				dealerAI.SwapDealerMesh()
				shellLoader.shotgunHand_L.visible = false
				shellLoader.shotgunHand_R.visible = false
				shotgunShooting.roundManager.dealerAtTable = false
				await get_tree().create_timer(.4, false).timeout
				speaker_crash.play()
				if (!dealerKilledSelf):
					#player shot dealer. eject shell and end turn here.
					shotgunShooting.ShootingDealerEjection(shotgunShooting.shellSpawner.sequenceArray[0], "dealer", false)
					pass
				await get_tree().create_timer(1.8, false).timeout
				if(shotgunShooting.roundManager.health_opponent == 0):
					shotgunShooting.roundManager.OutOfHealth("dealer")
					healthCounter.UpdateDisplayRoutine(false, false, true)
					return
				if (shotgunShooting.roundManager.health_player == 0):
					shotgunShooting.roundManager.OutOfHealth("player")
					return
				if (dealerKilledSelf): healthCounter.checkingPlayer = true
				else: healthCounter.checkingPlayer = false
				await(healthCounter.UpdateDisplayRoutine(false, true, false))
				if (!shotgunShooting.roundManager.dealerCuffed): 
					animator_dealerHands.play("dealer hands on table")
					shotgunShooting.roundManager.waitingForDealerReturn = true
				else: 
					animator_dealerHands.play("dealer hands on table cuffed")
					shotgunShooting.roundManager.waitingForReturn = true
				animator_dealer.play("dealer return to table")
				await get_tree().create_timer(2, false).timeout
				if (dealerKilledSelf): dealerAI.EndDealerTurn(dealerAI.dealerCanGoAgain)
