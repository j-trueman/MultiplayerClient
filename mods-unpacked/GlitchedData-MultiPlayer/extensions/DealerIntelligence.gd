extends "res://scripts/DealerIntelligence.gd"

var manager
var dealerHasShot = false

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/MultiplayerRoundManager")
	manager.actionValidation.connect(PerformDealerAction)
#	manager.timeoutAdenaline.connect(Timeout)

func Timeout():
	stealing = false

func BeginDealerTurn():
	mainLoopFinished = false
	usingHandsaw = false
	dealerHasShot = false
	if (roundManager.requestedWireCut):
		await(roundManager.defibCutter.CutWire(roundManager.wireToCut))
	if (shellSpawner.sequenceArray.size() == 0):
		roundManager.StartRound(true)
		return
	roundManager.playerTurn = false
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	while !dealerHasShot:
		await manager.actionValidation

func PerformDealerAction(action, result):
	if not roundManager.playerTurn:
		match action:
			"invalid": return
			"pickup shotgun":
				dealerHasShot = true
				if (roundManager.waitingForDealerReturn):
					await get_tree().create_timer(1.8, false).timeout
				if not dealerHoldingShotgun:
					GrabShotgun()
					await get_tree().create_timer(1.4 + .5 - 1, false).timeout
				manager.receiveActionReady.rpc()
				await manager.smartAwait("action ready")
			"shoot self":
				Shoot_New("self", result)
			"shoot opponent":
				Shoot_New("player", result)
			_:
				var dealerIdx = 1 if manager.players[0] == multiplayer.get_unique_id() else 0
				var action_temp = action
				action = itemManager.itemsOnTable[dealerIdx][int(action)]
				if dealerHoldingShotgun:
					animator_shotgun.play("enemy put down shotgun")
					shellLoader.DealerHandsDropShotgun()
					dealerHoldingShotgun = false
					await get_tree().create_timer(.45, false).timeout
				dealerUsedItem = true
				if (roundManager.waitingForDealerReturn):
					await get_tree().create_timer(1.8, false).timeout
					roundManager.waitingForDealerReturn = false

				var returning = false
				if (action == "expired medicine"):
					var medicine_outcome		
					var dying = result
					medicine.dealerDying = dying
				if (action == "beer"):
					shellSpawner.sequenceArray[0] = "live" if bool(result) else "blank"
				var amountArray : Array[AmountResource] = amounts.array_amounts
				for res in amountArray:
					if (action == res.itemName):
						res.amount_dealer -= 1
						break
		
				if not stealing and action == "adrenaline":
					stealing = true
				elif stealing:
					hands.stealing = stealing
					stealing = false
				await(hands.PickupItemFromTable(action_temp))
				#if (action == "handcuffs"): await get_tree().create_timer(.8, false).timeout #additional delay for initial player handcuff check (continues outside animation)
				if (action == "cigarettes"): await get_tree().create_timer(1.1, false).timeout #additional delay for health update routine (called in aninator. continues outside animation)
				itemManager.itemArray_dealer.erase(action)
				itemManager.itemsOnTable[dealerIdx][int(action_temp)] = ""
				if (not stealing): itemManager.numberOfItemsGrabbed_enemy -= 1
				if (shellSpawner.sequenceArray.size() == 0 or roundManager.health_opponent == 0):
					dealerHasShot = true
					EndDealerTurn(false)

func Shoot_New(who : String, shell : int):
	var currentRoundInChamber = "live" if bool(shell) else "blank"
	shellSpawner.sequenceArray[0] = currentRoundInChamber
	dealerCanGoAgain = false
	var playerDied = false
	var dealerDied = false
	ejectManager.FadeOutShell()
	#ANIMATION DEPENDING ON WHO IS SHOT
	match(who):
		"self":
			await get_tree().create_timer(.2, false).timeout
			animator_shotgun.play("enemy shoot self")
			await get_tree().create_timer(2, false).timeout
			shotgunShooting.whoshot = "dealer"
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			shotgunShooting.PlayShootingSound_New(currentRoundInChamber)
			pass
		"player":
			animator_shotgun.play("enemy shoot player")
			await get_tree().create_timer(2, false).timeout
			shotgunShooting.whoshot = "player"
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
			shotgunShooting.PlayShootingSound_New(currentRoundInChamber)
			pass
	#SUBTRACT HEALTH. ASSIGN DEALER CAN GO AGAIN. RETURN IF DEAD
	if (currentRoundInChamber == "live" && who == "self"): 
		roundManager.health_opponent -= roundManager.currentShotgunDamage
		if (roundManager.health_opponent < 0): roundManager.health_opponent = 0
		smoke.SpawnSmoke("barrel")
		cameraShaker.Shake()
		dealerCanGoAgain = false
		death.Kill("dealer", false, true)
		return
	if (currentRoundInChamber == "live" && who == "player"): 
		roundManager.health_player -= roundManager.currentShotgunDamage
		if (roundManager.health_player < 0): roundManager.health_player = 0
		cameraShaker.Shake()
		smoke.SpawnSmoke("barrel")
		await(death.Kill("player", false, false))
		playerDied = true
	if (currentRoundInChamber == "blank" && who == "self"): dealerCanGoAgain = true
	#EJECTING SHELLS
	await get_tree().create_timer(.4, false).timeout
	if roundManager.health_player > 0:
		if (who == "player"): animator_shotgun.play("enemy eject shell_from player")
		if (who == "self"): animator_shotgun.play("enemy eject shell_from self")
		await get_tree().create_timer(1.7, false).timeout
	#shellSpawner.sequenceArray.remove_at(0)
	EndDealerTurn(dealerCanGoAgain)

