extends "res://scripts/HandManager.gd"

var manager

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")

func PickupItemFromTable(itemName : String):
	var dealerIdx = 1 if manager.players[0].values()[0] == manager.get_parent().myInfo["Name"] else 0
	var itemIdx = int(itemName)
	itemName = itemManager.itemsOnTable[dealerIdx][itemIdx] if not stealing else itemManager.itemsOnTable[int(not dealerIdx)][itemIdx]
	dealerAI.Speaker_HandCrack()
	var activeIndex
	var activeInstance
	var whichHandToGrabWith
	var whichGridSide
	var matchIndex
	activeItemToGrab = itemName 
	for i in range(itemManager.itemArray_instances_dealer.size()):
		if (itemIdx == itemManager.itemArray_instances_dealer[i].get_child(1).itemGridIndex and itemManager.itemArray_instances_dealer[i].get_child(1).isPlayerSide == stealing):
			activeInstance = itemManager.itemArray_instances_dealer[i]
			matchIndex = i
			break
	activeIndex = activeInstance.get_child(0).dealerGridIndex
	ToggleHandVisible("BOTH", false)
	hand_defaultL.visible = true
	hand_defaultR.visible = true
	if (itemName == "beer" or itemName == "cigarettes" or itemName == "expired medicine" or itemName == "inverter" or itemName == "adrenaline"): whichHandToGrabWith = "left"
	else: whichHandToGrabWith = "right"
	whichGridSide = activeInstance.get_child(0).whichSide
	animator_hands.play("RESET")
	BeginHandLerp(whichHandToGrabWith, activeIndex, whichGridSide)
	if (whichGridSide == "right"): animator_dealerHeadLook.play("dealer look right")
	else: animator_dealerHeadLook.play("dealer look left")
	if (stealing):
		if (whichGridSide == "right"): cam.BeginLerp("player item grid left")
		else: cam.BeginLerp("player item grid right")
		var amountArray : Array[AmountResource] = amounts.array_amounts
		for res in amountArray:
			if res.itemName == itemName: res.amount_player -= 1
			break
	await get_tree().create_timer(lerpDuration -.4, false).timeout
	if (whichHandToGrabWith == "right"): hand_defaultR.visible = false
	else: hand_defaultL.visible = false
	dealerAI.Speaker_HandCrack()
	match (itemName):
		"handsaw":
			hand_handsaw.visible = true
			dealerAI.roundManager.barrelSawedOff = true
			dealerAI.roundManager.currentShotgunDamage = 2
		"magnifying glass":
			hand_magnifier.visible = true
		"handcuffs":
			hand_handcuffs.visible = true
			dealerAI.roundManager.playerCuffed = true
		"cigarettes":
			hand_cigarettepack.visible = true
			itemManager.numberOfCigs_dealer -= 1
		"beer":
			hand_beer.visible = true
		"expired medicine":
			hand_medicine.visible = true
		"inverter":
			hand_inverter.visible = true
		"burner phone":
			hand_burnerphone.visible = true
		"adrenaline":
			hand_adrenaline.visible = true
	itemManager.itemArray_instances_dealer.remove_at(matchIndex)
	var tempindicator = activeInstance.get_child(0)
	var gridname = tempindicator.dealerGridName
	if (!stealing): itemManager.gridParentArray_enemy_available.append(gridname)
	if (stealing): inter.RemovePlayerItemFromGrid(activeInstance)
	activeInstance.queue_free()
	await get_tree().create_timer(.2, false).timeout
	ReturnHand()
	if (stealing):
		cam.BeginLerp("enemy")
	if (whichGridSide == "right"): animator_dealerHeadLook.play("dealer look forward from right")
	else: animator_dealerHeadLook.play("dealer look forward from left")
	await get_tree().create_timer(lerpDuration + .01, false).timeout
	HandFailsafe()
	var animationName = "dealer use " + itemName
	PlaySound(itemName)
	animator_hands.play("RESET")
	animator_hands.play(animationName)
	var length = animator_hands.get_animation(animationName).get_length()
	moving = false
	await get_tree().create_timer(length, false).timeout
	stealing = false
	if (dealerAI.shellSpawner.sequenceArray.size() > 0):
		manager.receiveActionReady.rpc()
		await manager.smartAwait("action ready")
	pass