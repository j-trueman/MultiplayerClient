extends "res://scripts/ItemManager.gd"

var manager
var itemsForPlayers

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	manager.items.connect(items)
	manager.adrenalineTimeout.connect(RevertItemSteal_Timeout)
	super()

func items(itemsForPlayers_var):
	itemsForPlayers = itemsForPlayers_var
	roundManager.roundArray[roundManager.currentRound].numberOfItemsToGrab = itemsForPlayers[0].size()

func BeginItemGrabbing():
	manager.receiveItems.rpc()
	super()
	await manager.smartAwait("items")

func CheckTimer():
	if ((timer_steal_current > timer_steal_max) && checking && !fs):
		fs = true
	pass

func GrabItem():
	if (roundManager.playerData.currentBatchIndex == 1 && roundManager.currentRound == 1):
		if (spook_counter == 1 && !spook_fired && !roundManager.playerData.seenGod):
			GrabSpook()
			roundManager.playerData.seenGod = true
			spook_fired = true
			return
		spook_counter += 1
	#GET RANDOM ITEM
	PlayItemGrabSound()
	interaction_intake.interactionAllowed = false
	var selectedResource : ItemResource

	#SET PLAYER AVAILABLE ITEMS ACCORDING TO MAX COUNTS
	var amountArray : Array[AmountResource] = amounts.array_amounts
	availableItemsToGrabArray_player = []
	for res in amountArray:
		if (res.amount_active == 0): continue
		if (res.amount_player != res.amount_active):
			availableItemsToGrabArray_player.append(res.itemName)
	#for res in amountArray: availableItemsToGrabArray_player.append(res.itemName)
	
	if (roundManager.currentRound == 0 && roundManager.roundArray[roundManager.currentRound].startingHealth == 2):
		if ("handsaw" in availableItemsToGrabArray_player): availableItemsToGrabArray_player.erase("handsaw")
	
	var playerIdx = 0 if manager.players[0].values()[0] == manager.get_parent().myInfo["Name"] else 1
	if itemsForPlayers[playerIdx].is_empty(): itemsForPlayers[playerIdx].append("handsaw")
	numberOfItemsGrabbed += 1
	#SPAWN ITEM
	for i in range(instanceArray.size()):
		if (itemsForPlayers[playerIdx].front() == instanceArray[i].itemName):
			selectedResource = instanceArray[i]
	itemsForPlayers[playerIdx].pop_front()
	var itemInstance = selectedResource.instance.instantiate()

	for res in amountArray:
		if (selectedResource.itemName == res.itemName):
			res.amount_player += 1
			break
	
	activeItem = itemInstance
	itemSpawnParent.add_child(itemInstance)
	itemInstance.transform.origin = selectedResource.pos_inBriefcase
	itemInstance.rotation_degrees = selectedResource.rot_inBriefcase
	activeItem_offset_pos = selectedResource.pos_offset
	activeItem_offset_rot = selectedResource.rot_offset
	#ADD ITEM TO PICKUP INDICATOR & INTERACTION BRANCH ARRAY
	if (numberOfOccupiedGrids != 8):
		temp_indicator = activeItem.get_child(0)
		temp_interaction = activeItem.get_child(1)
		items_dynamicIndicatorArray.append(temp_indicator)
		items_dynamicInteractionArray.append(temp_interaction)
		var ind = items_dynamicIndicatorArray.size() - 1
		temp_indicator.locationInDynamicArray = ind
	#DISABLE ITEM COLLIDER
	var childArray = activeItem.get_children()
	for i in childArray.size():
		if (childArray[i] is StaticBody3D): childArray[i].get_child(0).disabled = true
	#LERP TO HAND
	pos_current = itemInstance.transform.origin
	rot_current = itemInstance.rotation_degrees
	pos_next = selectedResource.pos_inHand
	rot_next = selectedResource.rot_inHand
	elapsed = 0
	moving = true
	await get_tree().create_timer(lerpDuration - .2, false).timeout
	if (!roundManager.playerData.indicatorShown): grid.ShowGridIndicator()
	
	if (numberOfOccupiedGrids != 8):
		
		GridParents(true)
		SetIntakeFocus(false)
	else:
		#NOT ENOUGH SPACE. PUT ITEM BACK AND END ITEM GRABBING
		for res in amountArray:
			if (selectedResource.itemName == res.itemName):
				res.amount_player -= 1
				break	
		dialogue.ShowText_Forever(tr("NO SPACE"))
		await get_tree().create_timer(1.8, false).timeout
		dialogue.ShowText_Forever(tr("UNFORTUNATE"))
		await get_tree().create_timer(2.2, false).timeout
		dialogue.HideText()
		pos_current = activeItem.transform.origin
		rot_current = activeItem.rotation_degrees
		pos_next = selectedResource.pos_inBriefcase
		rot_next = selectedResource.rot_inBriefcase
		elapsed = 0
		moving = true
		cursor.SetCursor(false, false)
		ClearIntakeFocus()
		PlayItemGrabSound()
		await get_tree().create_timer(lerpDuration, false).timeout
		moving = false
		activeItem.queue_free()
		EndItemGrabbing()
	pass

func GrabItems_Enemy():
	var selectedResource
	var dealerIdx = 1 if manager.players[0].values()[0] == manager.get_parent().myInfo["Name"] else 0
	for i in range(roundManager.roundArray[roundManager.currentRound].numberOfItemsToGrab):
		if (numberOfItemsGrabbed_enemy != 8):

			var amountArray : Array[AmountResource] = amounts.array_amounts
			availableItemsToGrabArray_dealer = []
			for res in amountArray:
				if (res.amount_active == 0): 
					continue
				if (res.amount_dealer != res.amount_active):
					availableItemsToGrabArray_dealer.append(res.itemName)
			
			if (roundManager.currentRound == 0 && roundManager.roundArray[roundManager.currentRound].startingHealth == 2):
				if ("handsaw" in availableItemsToGrabArray_dealer): availableItemsToGrabArray_dealer.erase("handsaw")
			
			#SPAWN ITEM
			for c in range(instanceArray_dealer.size()):
				if (itemsForPlayers[dealerIdx].front() == instanceArray_dealer[c].itemName):
					selectedResource = instanceArray_dealer[c]
					#ADD STRING TO DEALER ITEM ARRAY
					itemArray_dealer.append(instanceArray_dealer[c].itemName.to_lower())
					break
			itemsForPlayers[dealerIdx].pop_front()
			var itemInstance = selectedResource.instance.instantiate()
			var temp_itemIndicator = itemInstance.get_child(0)
			temp_itemIndicator.isDealerItem = true
			for res in amountArray:
				if (selectedResource.itemName == res.itemName):
					res.amount_dealer += 1
					break
			
			#ADD INSTANCE TO DEALER ITEM ARRAY (mida vittu this code is getting out of hand)
			itemArray_instances_dealer.append(itemInstance)
			activeItem_enemy = itemInstance
			itemSpawnParent.add_child(activeItem_enemy)
			
			#PLACE ITEM ON RANDOM GRID
			var randgrid = randi_range(0, gridParentArray_enemy_available.size() - 1)
			var gridname = gridParentArray_enemy_available[randgrid]
			activeItem_enemy.transform.origin = gridParentArray_enemy_available[randgrid].transform.origin + selectedResource.pos_offset
			activeItem_enemy.rotation_degrees = gridParentArray_enemy_available[randgrid].rotation_degrees + selectedResource.rot_offset
			if (activeItem_enemy.transform.origin.z > 0): temp_itemIndicator.whichSide = "right"
			else: temp_itemIndicator.whichSide = "left"
			temp_itemIndicator.dealerGridIndex = gridParentArray_enemy_available[randgrid].get_child(0).activeIndex
			temp_itemIndicator.dealerGridName = gridname
			if (activeItem_enemy.get_child(1).itemName == "cigarettes"): numberOfCigs_dealer += 1
			gridParentArray_enemy_available.erase(gridname)
			numberOfItemsGrabbed_enemy += 1

func EndItemGrabbing():
	GrabItems_Enemy()
	GridParents(false)
	interaction_intake.interactionAllowed = false
	cursor.SetCursor(false, false)
	ClearIntakeFocus()
	await get_tree().create_timer(.45, false).timeout
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	comp.CycleCompartment("hide briefcase")
	await get_tree().create_timer(1, false).timeout
	camera.BeginLerp("home")
	await get_tree().create_timer(.9, false).timeout
	moving = false
	roundManager.ReturnFromItemGrabbing()
	pass
