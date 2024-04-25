extends "res://scripts/InteractionManager.gd"

var manager
var burnerPhone
var action = ""
var result = null

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	manager.actionValidation.connect(actionValidation)
	burnerPhone = GlobalVariables.get_current_scene_node().get_node("standalone managers/burner phone manager")

func actionValidation(action_var, result_var):
	action = action_var
	result = result_var

func InteractWith(alias : String):
	match alias:
		"item":
			manager.receiveActionValidation.rpc(activeInteractionBranch.itemName)
			await manager.smartAwait("action validation")
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
	super(alias)
	match alias:
		"shotgun":
			manager.receiveActionReady.rpc()
			await manager.smartAwait("action ready")