extends "res://scripts/DealerIntelligence.gd"

var manager
var dealerHasShot = false

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	manager.actionValidation.connect(PerformDealerAction)

func BeginDealerTurn():
	mainLoopFinished = false
	usingHandsaw = false
	dealerHasShot = false
	if (roundManager.requestedWireCut):
		await(roundManager.defibCutter.CutWire(roundManager.wireToCut))
	if (shellSpawner.sequenceArray.size() == 0):
		roundManager.StartRound(true)
		return
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
				inv_playerside = []
				inv_dealerside = []
				itemManager.itemArray_dealer = []
				itemManager.itemArray_instances_dealer = []
				var usingAdrenaline = false
				var ch = itemManager.itemSpawnParent.get_children()
				for c in ch.size():
					if(ch[c].get_child(0) is PickupIndicator):
						var temp_interaction : InteractionBranch = ch[c].get_child(1)
						if (temp_interaction.itemName == "adrenaline" && !temp_interaction.isPlayerSide):
							usingAdrenaline = true
							adrenalineSetup	= true
				for c in ch.size():
					if(ch[c].get_child(0) is PickupIndicator):
						var temp_indicator : PickupIndicator = ch[c].get_child(0)
						var temp_interaction : InteractionBranch = ch[c].get_child(1)
						if (ch[c].transform.origin.z > 0): temp_indicator.whichSide = "right"
						else: temp_indicator.whichSide= "left"
						if (!temp_interaction.isPlayerSide):
							inv_dealerside.append(temp_interaction.itemName)
							itemManager.itemArray_dealer.append(temp_interaction.itemName)
							itemManager.itemArray_instances_dealer.append(ch[c])
				for c in ch.size():
					if(ch[c].get_child(0) is PickupIndicator):
						var temp_indicator : PickupIndicator = ch[c].get_child(0)
						var temp_interaction : InteractionBranch = ch[c].get_child(1)
						if (ch[c].transform.origin.z > 0): temp_indicator.whichSide = "right"
						else: temp_indicator.whichSide= "left"
						if (temp_interaction.isPlayerSide && usingAdrenaline): 
							itemManager.itemArray_dealer.append(temp_interaction.itemName)
							itemManager.itemArray_instances_dealer.append(ch[c])
							inv_playerside.append(temp_interaction.itemName)

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
					returning = true

				var amountArray : Array[AmountResource] = amounts.array_amounts
				for res in amountArray:
					if (action == res.itemName):
						res.amount_dealer -= 1
						break
		
				var stealingFromPlayer = true
				for i in range(inv_dealerside.size()):
					if (inv_dealerside[i] == action): stealingFromPlayer = false
				var subtracting = true
				var temp_stealing = false
				for i in range(itemManager.itemArray_instances_dealer.size()):
					if (itemManager.itemArray_instances_dealer[i].get_child(1).itemName == action && itemManager.itemArray_instances_dealer[i].get_child(1).isPlayerSide && action != "adrenaline" && adrenalineSetup && stealingFromPlayer):
						temp_stealing = true
						await(hands.PickupItemFromTable("adrenaline"))
						itemManager.numberOfItemsGrabbed_enemy -= 1
						subtracting = false
						adrenalineSetup = false
						break
		
				if (temp_stealing): hands.stealing = true
				await(hands.PickupItemFromTable(action))
				#if (action == "handcuffs"): await get_tree().create_timer(.8, false).timeout #additional delay for initial player handcuff check (continues outside animation)
				if (action == "cigarettes"): await get_tree().create_timer(1.1, false).timeout #additional delay for health update routine (called in aninator. continues outside animation)
				itemManager.itemArray_dealer.erase(action)
				if (subtracting): itemManager.numberOfItemsGrabbed_enemy -= 1
				if (roundManager.shellSpawner.sequenceArray.size() != 0):
					manager.receiveActionReady.rpc()
					await manager.smartAwait("action ready")
				return

func Shoot_New(who : String, shell : int):
	var currentRoundInChamber = "live" if bool(shell) else "blank"
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
			shotgunShooting.PlayShootingSound_New(currentRoundInChamber)
			pass
		"player":
			animator_shotgun.play("enemy shoot player")
			await get_tree().create_timer(2, false).timeout
			shotgunShooting.whoshot = "player"
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
	if (who == "player"): animator_shotgun.play("enemy eject shell_from player")
	if (who == "self"): animator_shotgun.play("enemy eject shell_from self")
	await get_tree().create_timer(1.7, false).timeout
	#shellSpawner.sequenceArray.remove_at(0)
	EndDealerTurn(dealerCanGoAgain)

