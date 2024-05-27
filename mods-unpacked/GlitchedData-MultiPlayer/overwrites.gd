extends Node

func _init():
	var overwrite_0 = preload("res://mods-unpacked/GlitchedData-MultiPlayer/overwrites/scripts/ButtonClass_Main.gd").new().get_script()
	overwrite_0.take_over_path("res://scripts/ButtonClass_Main.gd")