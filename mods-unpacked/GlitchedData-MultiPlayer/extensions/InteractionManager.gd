extends "res://scripts/InteractionManager.gd"

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
		super(alias)
		busy = false