extends "res://scripts/MedicineManager.gd"

var manager
var isDying

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")

func UseMedicine():
	cam.moving = false
	await get_tree().create_timer(3.05, false).timeout
	death.DisableSpeakers()
	await get_tree().create_timer(1.25 + .1, false).timeout
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	if (isDying):
		Perms(4.38)
		counter.skipping_careful = true
		rm.health_player -= 1
		speaker_medicine.stream = death_player
		speaker_medicine.play()
		await(death.MedicineDeath())
		counter.overriding_medicine = true
		counter.overriding_medicine_adding = false
		counter.UpdateDisplayRoutineCigarette_Player()
	else:
		Perms(2.38)
		death.FadeInSpeakers()
		counter.overriding_medicine = true
		counter.overriding_medicine_adding = true
		counter.UpdateDisplayRoutineCigarette_Player()

func UseMedicine_Dealer():
	var dying = dealerDying
	if (dying):
		await get_tree().create_timer(5, false).timeout
		manager.receiveActionReady.rpc()
		await manager.smartAwait("action ready")
		speaker_medicine.stream = death_dealer
		speaker_medicine.play()
		anim_dealerhands.play("dealer death medicine")
		await get_tree().create_timer(.41, false).timeout
		death.cameraShaker.Shake()
		await get_tree().create_timer(.6, false).timeout
		#rm.health_opponent -= 1
		counter.overriding_medicine = true
		counter.overriding_medicine_adding = false
		counter.UpdateDisplayRoutineCigarette_Enemy()
		await get_tree().create_timer(.5, false).timeout
		anim_dealerhands.play("RESET")
		await get_tree().create_timer(2, false).timeout
		dealerDying = false
	else:
		await get_tree().create_timer(4.07, false).timeout
		manager.receiveActionReady.rpc()
		await manager.smartAwait("action ready")
		counter.overriding_medicine = true
		counter.overriding_medicine_adding = true
		counter.UpdateDisplayRoutineCigarette_Enemy()
		await get_tree().create_timer(2, false).timeout
		dealerDying = false