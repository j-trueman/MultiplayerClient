extends "res://scripts/ItemManager.gd"

var manager
var itemsForPlayers
var itemTableIdxArray = []
var itemsOnTable = [["","","","","","","",""],
			["","","","","","","",""]]

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/MultiplayerRoundManager")
	manager.items.connect(items)
	manager.itemsOnTable_signal.connect(GrabItems_Enemy_New)
	manager.timeoutAdrenaline.connect(RevertItemSteal_Timeout)
	super()

func items(itemsForPlayers_var):
	await get_tree().create_timer(1, false).timeout
	itemsForPlayers = itemsForPlayers_var
	if manager.players:
		var playerIdx = 0 if manager.players[0] == multiplayer.get_unique_id() else 1
		roundManager.roundArray[roundManager.currentRound].numberOfItemsToGrab = itemsForPlayers[playerIdx].size()

func BeginItemGrabbing():
	itemTableIdxArray.clear()
	manager.receiveItems.rpc()
	roundManager.ignoring = false
	numberOfItemsGrabbed = 0
	if (roundManager.playerData.hasReadItemSwapIntroduction): camera.BeginLerp("home")
	else: camera.BeginLerp("enemy")
	var itemParentChildrenArray = itemSpawnParent.get_children()
	#CLEAR ITEMS FROM TABLE
	if (newBatchHasBegun):
		for i in range(itemParentChildrenArray.size()):
			if (itemParentChildrenArray[i].get_child(0) is PickupIndicator):
				requestingItemClear = true
				break
		if (requestingItemClear):
			await get_tree().create_timer(.8, false).timeout
			SetupItemClear()
			comp.animator_compartment.play("clear items")
			await get_tree().create_timer(1.4).timeout
		newBatchHasBegun = false
	
	await get_tree().create_timer(.8, false).timeout
	if (!roundManager.playerData.hasReadItemSwapIntroduction):
		dialogue.ShowText_ForDuration(tr("MORE INTERESTING"), 3)
		await get_tree().create_timer(3, false).timeout
		camera.BeginLerp("home")
		await get_tree().create_timer(.8, false).timeout
		roundManager.playerData.hasReadItemSwapIntroduction = true
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")
	comp.CycleCompartment("show briefcase")
	await get_tree().create_timer(.8, false).timeout
	if (comp.isHiding_items): comp.CycleCompartment("show items")
	await get_tree().create_timer(.8, false).timeout
	camera.BeginLerp("briefcase")
	await get_tree().create_timer(.8, false).timeout
	
	if (!roundManager.playerData.hasReadItemDistributionIntro):
		var stringIndex = roundManager.roundArray[roundManager.currentRound].numberOfItemsToGrab
		var string = stringNumberArray[stringIndex]
		string = str(stringIndex)
		dialogue.ShowText_Forever(tr("ITEMS EACH") % string)
		await get_tree().create_timer(2.5, false).timeout
		dialogue.ShowText_Forever(tr("MORE ITEMS"))
		await get_tree().create_timer(2.5, false).timeout
		dialogue.HideText()
		roundManager.playerData.hasReadItemDistributionIntro = true

	if (!roundManager.playerData.hasReadItemDistributionIntro2 && roundManager.roundArray[roundManager.currentRound].hasIntro2):
		var stringIndex = roundManager.roundArray[roundManager.currentRound].numberOfItemsToGrab
		var string = stringNumberArray[stringIndex]
		string = str(stringIndex)
		dialogue.ShowText_Forever(tr("ITEMS EACH") % string)
		await get_tree().create_timer(2.5, false).timeout
		dialogue.HideText()
		roundManager.playerData.hasReadItemDistributionIntro2 = true
	await manager.smartAwait("items")
	var playerIdx = 0 if manager.players[0] == multiplayer.get_unique_id() else 1
	if itemsForPlayers[playerIdx].size() > 0:
		#ALLOW ITEM GRAB
		cursor.SetCursor(true, true)
		SetIntakeFocus(true)
		interaction_intake.interactionAllowed = true
	else:
		EndItemGrabbing()

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
	
	var playerIdx = 0 if manager.players[0] == multiplayer.get_unique_id() else 1
	if itemsForPlayers[playerIdx].is_empty(): itemsForPlayers[playerIdx].append("handsaw")
	numberOfItemsGrabbed += 1
	#SPAWN ITEM
	for i in range(instanceArray.size()):
		if (itemsForPlayers[playerIdx].front() == instanceArray[i].itemName):
			selectedResource = instanceArray[i]
	var itemName = itemsForPlayers[playerIdx].pop_front()
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

func GrabItems_Enemy_New(itemsOnTable_var):
	var itemsOnTable_prev = itemsOnTable
	itemsOnTable = itemsOnTable_var
	var dealerIdx = 1 if manager.players[0] == multiplayer.get_unique_id() else 0
	for i in range(8):
		if itemsOnTable_prev[dealerIdx][i] == itemsOnTable[dealerIdx][i]: continue
		
		var selectedResource
		for c in range(instanceArray_dealer.size()):
			if (itemsOnTable[dealerIdx][i] == instanceArray_dealer[c].itemName):
				selectedResource = instanceArray_dealer[c]
				itemArray_dealer.append(instanceArray_dealer[c].itemName.to_lower())
				break
		
		for j in range(itemArray_instances_dealer.size()):
			if itemArray_instances_dealer[j].get_child(1).itemGridIndex == i:
				itemArray_instances_dealer.remove_at(j)
				break
		for item in itemSpawnParent.get_children():
			if item.get_child(0).isDealerItem and item.get_child(1).itemGridIndex == i:
				item.queue_free()
				break
				
		var itemInstance = selectedResource.instance.instantiate()
		var temp_itemIndicator = itemInstance.get_child(0)
		temp_itemIndicator.isDealerItem = true
		itemInstance.get_child(1).itemGridIndex = i
		itemArray_instances_dealer.append(itemInstance)
		activeItem_enemy = itemInstance
		itemSpawnParent.add_child(activeItem_enemy)
		
		var randgrid = 7 - i
		var gridname = gridParentArray_enemy[randgrid]
		activeItem_enemy.transform.origin = gridParentArray_enemy[randgrid].transform.origin + selectedResource.pos_offset
		activeItem_enemy.rotation_degrees = gridParentArray_enemy[randgrid].rotation_degrees + selectedResource.rot_offset
		if (activeItem_enemy.transform.origin.z > 0): temp_itemIndicator.whichSide = "right"
		else: temp_itemIndicator.whichSide = "left"
		temp_itemIndicator.dealerGridIndex = gridParentArray_enemy[randgrid].get_child(0).activeIndex
		temp_itemIndicator.dealerGridName = gridname

func PlaceDownItem(gridIndex : int):
	itemTableIdxArray.append(gridIndex)
	super(gridIndex)

func EndItemGrabbing():
	GridParents(false)
	interaction_intake.interactionAllowed = false
	cursor.SetCursor(false, false)
	ClearIntakeFocus()
	manager.actionReady_smart = true	# For "waiting for opponent" message
	manager.receiveItemsOnTable.rpc(itemTableIdxArray)
	await manager.itemsOnTable_signal
	manager.actionReady_smart = false
	await get_tree().create_timer(.45, false).timeout
	comp.CycleCompartment("hide briefcase")
	await get_tree().create_timer(1, false).timeout
	camera.BeginLerp("home")
	await get_tree().create_timer(.9, false).timeout
	moving = false
	roundManager.ReturnFromItemGrabbing()
	pass
