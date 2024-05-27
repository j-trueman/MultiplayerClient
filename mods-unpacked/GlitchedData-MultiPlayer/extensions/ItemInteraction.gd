extends "res://scripts/ItemInteraction.gd"

var manager

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/MultiplayerRoundManager")

func InteractWith(itemName : String):
	#INTERACTION
	var amountArray : Array[AmountResource] = amounts.array_amounts
	for res in amountArray:
		if (res.itemName == itemName): 
			res.amount_player -= 1
			break
	
	var isdup = false
	for it in roundManager.playerCurrentTurnItemArray:
		if (it == itemName): isdup = true; break
	if (!isdup): roundManager.playerCurrentTurnItemArray.append(itemName)
	match (itemName):
		"handcuffs":
			animator_dealerHands.play("dealer get handcuffed")
			await get_tree().create_timer(1, false).timeout
			camera.BeginLerp("enemy")
			await get_tree().create_timer(1.3, false).timeout
			camera.BeginLerp("dealer handcuffs")
			roundManager.dealerCuffed = true
			dealerIntelligence.dealerAboutToBreakFree = false
			await get_tree().create_timer(1.3, false).timeout
			camera.BeginLerp("home")
			await get_tree().create_timer(.6, false).timeout
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			EnablePermissions()
		"beer":
			roundManager.playerData.stat_beerDrank += 330
			var isFinalShell = false
			if (roundManager.shellSpawner.sequenceArray.size() == 1): isFinalShell = true
			animator_playerHands.play("player use beer")
			await get_tree().create_timer(1.4, false).timeout
			shellEject_player.FadeOutShell()
			await get_tree().create_timer(4.2, false).timeout
			#check if ejected last shell
			if (!isFinalShell):
				manager.receiveActionReady.rpc()
				await manager.smartAwait("action ready")
				EnablePermissions()
			else:
				roundManager.StartRound(true)
		"magnifying glass":
			animator_playerHands.play("player use magnifier")
			var length = animator_playerHands.get_animation("player use magnifier").get_length()
			await get_tree().create_timer(length + .2, false).timeout
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			EnablePermissions()
		"cigarettes":
			roundManager.playerData.stat_cigSmoked += 1
			animator_playerHands.play("player use cigarettes")
			await get_tree().create_timer(5, false).timeout
			itemManager.numberOfCigs_player -= 1
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			EnablePermissions()
		"handsaw":
			animator_playerHands.play("player use handsaw")
			roundManager.barrelSawedOff = true
			roundManager.currentShotgunDamage = 2
			await get_tree().create_timer(4.28 + .2, false).timeout
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			EnablePermissions()
		"expired medicine":
			PlaySound(sound_use_medicine)
			animator_playerHands.play("player use expired pills")
			medicine.UseMedicine()
			#await get_tree().create_timer(4.28 +.2 + 4.3, false).timeout
			#EnablePermissions()
		"inverter":
			PlaySound(sound_use_inverter)
			animator_playerHands.play("player use inverter")
			if (roundManager.shellSpawner.sequenceArray[0] == "live"): roundManager.shellSpawner.sequenceArray[0] = "blank"
			else: roundManager.shellSpawner.sequenceArray[0] = "live"
			await get_tree().create_timer(3.2, false).timeout
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			EnablePermissions()
		"burner phone":
			PlaySound(sound_use_burnerphone)
			animator_playerHands.play("player use burner phone")
			await get_tree().create_timer(7.9, false).timeout
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			EnablePermissions()
		"adrenaline":
			PlaySound(sound_use_adrenaline)
			animator_playerHands.play("player use adrenaline")
			await get_tree().create_timer(5.3 + .2, false).timeout
			items.SetupItemSteal()
			#EnablePermissions()
	CheckAchievement_koni()
	CheckAchievement_full()