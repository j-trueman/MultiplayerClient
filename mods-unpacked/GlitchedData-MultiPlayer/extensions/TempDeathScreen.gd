extends "res://scripts/TempDeathScreen.gd"

func _ready():
	if (isDeathScreen):
		print("changing scene to: main")
		get_tree().change_scene_to_file("res://mods-unpacked/GlitchedData-MultiPlayer/scenes/main.tscn")