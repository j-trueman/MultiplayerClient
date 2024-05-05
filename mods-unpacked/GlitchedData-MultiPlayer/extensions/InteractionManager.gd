extends "res://scripts/InteractionManager.gd"

var manager
var burnerPhone
var action = ""
var result = null
var actionValidation_flag = false
var badEnding = false

signal newAction

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	manager.actionValidation.connect(actionValidation)
	burnerPhone = GlobalVariables.get_current_scene_node().get_node("standalone managers/burner phone manager")

func actionValidation(action_var, result_var):
	action = action_var
	result = result_var
	actionValidation_flag = true
	emit_signal("newAction")

func InteractWith(alias : String):
	match alias:
		"item":
			var playerIdx = 0 if manager.players[0].values()[0] == manager.get_parent().myInfo["Name"] else 1
			var idx = str(activeInteractionBranch.itemGridIndex)
			actionValidation_flag = false
			manager.receiveActionValidation.rpc(idx)
			await manager.smartAwait("action validation")
			if not actionValidation_flag: await newAction
			if action.length() == 1:
				action = itemManager.itemsOnTable[playerIdx][int(idx)]
				itemManager.itemsOnTable[playerIdx][int(idx)] = ""
			match action:
				"invalid": return
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
				manager.receiveActionReady.rpc()
				await manager.smartAwait("action ready")
				badEnding = true
		"briefcase lid":
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")
	super(alias)