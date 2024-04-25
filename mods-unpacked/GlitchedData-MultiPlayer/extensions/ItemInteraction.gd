extends "res://scripts/ItemInteraction.gd"

var manager

func _ready():
	manager = get_tree().get_root().get_node("MultiplayerManager/multiplayer round manager")

func PickupItemFromTable(itemParent : Node3D, passedItemName : String):
	super(itemParent, passedItemName)
	manager.receiveActionReady.rpc()
	await manager.smartAwait("action ready")