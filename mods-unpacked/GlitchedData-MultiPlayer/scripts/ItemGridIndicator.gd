extends Node

const RoundManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/RoundManager.gd")

@export var roundManager : RoundManager
@export var animator : AnimationPlayer
@export var parent: Node3D

func ShowGridIndicator():
	parent.visible = true
	animator.play("show")
	roundManager.playerData.indicatorShown = true
	await get_tree().create_timer(1, false).timeout
	parent.visible = false