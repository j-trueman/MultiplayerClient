extends Node

const RoundManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/RoundManager.gd")

@export var rm : RoundManager
@export var statue : Node3D
@export var cup : Node3D

func CheckStatus():
	if (rm.playerData.playername == " vellon"):
		cup.visible = false
		statue.visible = true