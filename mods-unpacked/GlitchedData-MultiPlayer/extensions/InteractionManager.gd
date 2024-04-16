extends "res://scripts/InteractionManager.gd"

var manager
var burnerPhone
var action = ""
var result = null

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")
	manager.actionValidation.connect(actionValidation)
	burnerPhone = get_tree().get_root().get_node("standalone managers/burner phone manager")

func actionValidation(action_var, result_var):
	action = action_var
	result = result_var

func InteractWith(alias : String):
	var interacted
	match alias:
		"item":
			manager.receiveActionValidation.rpc(activeInteractionBranch.itemName)
			manager.smartAwait("action validation")
			match action:
				"invalid": return
				"magnifying glass", "beer": itemInteraction.roundManager.shellSpawner.sequenceArray[0] = "live" if bool(result) else "blank"
				"expired medicine": itemInteraction.medicine.isDying = result
				"burner phone": burnerPhone.info = result
			action = ""
			result = null
		"text dealer", "text you":
			manager.receiveActionValidation("shoot self" if alias == "text you" else "shoot opponent")
			shotgun.result = result
	super(alias)