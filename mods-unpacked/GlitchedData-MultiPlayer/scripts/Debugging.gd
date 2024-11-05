extends Node

const TimeScaleManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/TimeScaleManager.gd")

@export var debugging : bool
@export var timescale : TimeScaleManager
func _unhandled_input(event):
	if (debugging):
		if (event.is_action_pressed(",")):
			Engine.time_scale = 1
			timescale.moving = false
		if (event.is_action_pressed(".")):
			Engine.time_scale = 10
			timescale.moving = false