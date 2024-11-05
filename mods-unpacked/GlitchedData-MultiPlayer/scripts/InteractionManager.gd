extends Node

const BriefcaseMachine = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/BriefcaseMachine.gd")
const CRT = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/CrtManager.gd")
const CursorManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/CursorManager.gd")
const DecisionTextManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/DecisionTextManager.gd")
const Heaven = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/HeavenManager.gd")
const InteractionBranch = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/InteractionBranch.gd")
const IntroManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/IntroManager.gd")
const ItemInteraction = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ItemInteraction.gd")
const ItemManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ItemManager.gd")
const MouseRaycast = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/MouseRaycast.gd")
const PickupIndicator = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/PickupIndicator.gd")
const ShotgunShooting = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ShotgunShooting.gd")
const SignButton = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/SignatureButtonBranch.gd")
const Signature = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/SignatureManager.gd")

@export var sign : Signature
@export var brief : BriefcaseMachine
@export var heaven : Heaven
@export var intro : IntroManager
@export var cursor : CursorManager
@export var mouseRay : MouseRaycast
@export var shotgun : ShotgunShooting
@export var decision : DecisionTextManager
@export var itemManager : ItemManager
@export var itemInteraction : ItemInteraction
@export var crt : CRT
var activeParent
var activeInteractionBranch
var checking = true

func _process(delta):
	CheckPickupLerp()
	CheckInteractionBranch()
	if (checking): CheckIfHovering()
	pass

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		MainInteractionEvent()

func MainInteractionEvent():
	if (activeInteractionBranch != null && activeInteractionBranch.interactionAllowed && !activeInteractionBranch.interactionInvalid):
		var childArray = activeInteractionBranch.get_parent().get_children()
		for i in range(childArray.size()): if (childArray[i] is PickupIndicator): childArray[i].SnapToMax()
		if (!activeInteractionBranch.isGrid): InteractWith(activeInteractionBranch.interactionAlias)
		else: InteractWithGrid(activeInteractionBranch.gridIndex)

func CheckIfHovering():
	if (activeInteractionBranch != null && activeInteractionBranch.interactionAllowed):
		if (activeInteractionBranch.interactionAllowed && !activeInteractionBranch.interactionInvalid):
			cursor.SetCursorImage("hover")
		else: if (activeInteractionBranch.interactionAllowed && activeInteractionBranch.interactionInvalid):
			cursor.SetCursorImage("invalid")
	else:
		cursor.SetCursorImage("point")

var fs_dec = false

func SignatureButtonRemote(assignedBranch : SignButton, alias : String):
	sign.GetInput(alias, alias)
	assignedBranch.Press()
	pass

func InteractWithGrid(tempGridIndex : int):
	itemManager.PlaceDownItem(tempGridIndex)
	pass

func CheckPickupLerp():
	if (mouseRay.result != null && mouseRay.result.has("collider") && cursor.cursor_visible):
		var parent = mouseRay.result.collider.get_parent()
		activeParent = parent
		var childArray = parent.get_children()
		for i in range(childArray.size()):
			if (childArray[i] is PickupIndicator):
				var indicator = childArray[i]
		pass
	else:	
		activeParent = null
	pass

func CheckInteractionBranch():
	var isFound = null
	if (activeParent != null):
		var childArray = activeParent.get_children()
		for i in range(childArray.size()):
			if (childArray[i] is InteractionBranch):
				var branch = childArray[i]
				# activeInteractionBranch = childArray[i]
				isFound = childArray[i]
				break
	if (isFound):
		activeInteractionBranch = isFound
	else:
		activeInteractionBranch = null

var multiManager
var manager
var burnerPhone
var action = ""
var result = null
var actionValidation_flag = false
var badEnding = false
var busy = false

signal newAction

func _ready():
	multiManager = get_tree().get_root().get_node("MultiplayerManager")
	manager = get_tree().get_root().get_node("MultiplayerManager/MultiplayerRoundManager")
	manager.actionValidation.connect(actionValidation)
	burnerPhone = GlobalVariables.get_current_scene_node().get_node("standalone managers/burner phone manager")

func actionValidation(action_var, result_var):
	action = action_var
	result = result_var
	actionValidation_flag = true
	emit_signal("newAction")

func InteractWith(alias : String):
	if not busy:
		busy = true
		match alias:
			"item":
				var playerIdx = 0 if manager.players[0] == multiplayer.get_unique_id() else 1
				var idx = str(activeInteractionBranch.itemGridIndex)
				actionValidation_flag = false
				manager.receiveActionValidation.rpc(idx)
				await manager.smartAwait("action validation")
				if not actionValidation_flag: await newAction
				if action.length() == 1 or action == "invalid":
					if action == "invalid":
						print("ERROR: INVALID ACTION. PROCEEDING WITH MATCH...")
						result = 0
					action = itemManager.itemsOnTable[playerIdx][int(idx)]
					itemManager.itemsOnTable[playerIdx][int(idx)] = ""
				match action:
					"invalid":
						busy = false
						return
					"magnifying glass", "beer": itemInteraction.roundManager.shellSpawner.sequenceArray[0] = "live" if bool(result) else "blank"
					"expired medicine": itemInteraction.medicine.isDying = result
					"burner phone": burnerPhone.info = result
			"shotgun":
				manager.receiveActionValidation.rpc("pickup shotgun")
				await manager.smartAwait("action validation")
			"text dealer":
				manager.receiveActionValidation.rpc("shoot opponent")
			"text you":
				manager.receiveActionValidation.rpc("shoot self")
			"latch left", "latch right":
				if not badEnding:
					if multiManager.opponentActive:
						manager.receiveActionReady.rpc()
						await manager.smartAwait("action ready")
					badEnding = true
			"briefcase lid":
				if multiManager.opponentActive:
					manager.receiveActionReady.rpc()
					await manager.smartAwait("action ready")
				multiManager.openedBriefcase = true
			"crt button":
				if (activeInteractionBranch.crtButton_alias != "" ):
					if (activeInteractionBranch.crtButton_alias == "right" or activeInteractionBranch.crtButton_alias == "left"):
						if multiManager.inviteMenu.popupVisible:
							busy = false
							return
					else: crt.Interaction(activeInteractionBranch.crtButton_alias)
		match(alias):
			"shotgun":
				shotgun.GrabShotgun()
			"text dealer":
				if (!fs_dec):
					shotgun.Shoot("dealer")
					decision.SetUI(false)
					fs_dec = true
			"text you":
				if (!fs_dec):
					shotgun.Shoot("self")
					decision.SetUI(false)
					fs_dec = true
			"briefcase intake":
				itemManager.GrabItem()
			"item":
				if (activeInteractionBranch.itemName != ""):
					itemInteraction.PickupItemFromTable(activeInteractionBranch.get_parent(), activeInteractionBranch.itemName)
			"bathroom door":
				intro.Interaction_BathroomDoor()
			"backroom door":
				intro.Interaction_BackroomDoor()
			"heaven door":
				heaven.Fly()
			"latch left":
				brief.OpenLatch("L")
			"latch right":
				brief.OpenLatch("R")
			"briefcase lid":
				brief.OpenLid()
			"release form on table":
				sign.PickUpWaiver()
			"signature machine button":
				sign.GetInput(activeInteractionBranch.signatureButton_letterAlias, activeInteractionBranch.signatureButton_specialAlias)
				activeInteractionBranch.assignedSignatureButton.Press()
			"pill bottle":
				intro.Interaction_PillBottle()
			"pill choice no":
				intro.SelectedPill(false)
			"pill choice yes":
				intro.SelectedPill(true)
			"double yes":
				shotgun.roundManager.Response(true)
			"double no":
				shotgun.roundManager.Response(false)
			"crt":
				intro.Interaction_CRT()
			"crt button":
				if (activeInteractionBranch.crtButton_alias != ""): 
					#activeInteractionBranch.get_parent().get_child(1).Press()
					crt.Interaction(activeInteractionBranch.crtButton_alias)
		busy = false
