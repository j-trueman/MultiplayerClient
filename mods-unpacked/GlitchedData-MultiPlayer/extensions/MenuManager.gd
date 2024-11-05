extends "res://scripts/MenuManager.gd"

func _ready():
	Show("main")
	buttons[0].connect("is_pressed", Start)
	buttons[1].connect("is_pressed", SubOptions)
	buttons[2].connect("is_pressed", Credits)
	buttons[3].connect("is_pressed", Exit)
	buttons[4].connect("is_pressed", ReturnToLastScreen)
	buttons[5].connect("is_pressed", ReturnToLastScreen)
	buttons[6].connect("is_pressed", ReturnToLastScreen)
	buttons[7].connect("is_pressed", Options_AudioVideo)
	buttons[8].connect("is_pressed", Options_Language)
	buttons[9].connect("is_pressed", Options_Controller)
	buttons[10].connect("is_pressed", ReturnToLastScreen)
	buttons[11].connect("is_pressed", ReturnToLastScreen)
	buttons[16].connect("is_pressed", RebindControls)
	buttons[17].connect("is_pressed", ReturnToLastScreen)
	buttons[18].connect("is_pressed", ResetControls)
	buttons[19].connect("is_pressed", DiscordLink)
	buttons[22].connect("is_pressed", Start)
	buttons[23].connect("is_pressed", ModsMenu)
	buttons[24].connect("is_pressed", ReturnToLastScreen)
	
	buttons_options[0].connect("is_pressed", IncreaseVol)
	buttons_options[1].connect("is_pressed", DecreaseVol)
	buttons_options[2].connect("is_pressed", SetFull)
	buttons_options[3].connect("is_pressed", SetWindowed)
	buttons_options[4].connect("is_pressed", ControllerEnable)
	buttons_options[5].connect("is_pressed", ControllerDisable)
	buttons_options[6].connect("is_pressed", ToggleColorblind)
	buttons_options[7].connect("is_pressed", ToggleMusic)
	
	version.text = GlobalVariables.currentVersion

	parent_modConfig = parent_mods.get_node("mod_list/MarginContainer/PanelContainer/VBoxContainer2")
	
	Intro()

func Start():
	multiplayer.multiplayer_peer = null
	Buttons(false)
	ResetButtons()
	for screen in screens: screen.visible = false
	title.visible = false
	controller.previousFocus = null
	speaker_music.stop()
	animator_intro.play("snap")
	for w in waterfalls: w.pause()
	speaker_start.play()
	cursor.SetCursor(false, false)
	savefile.ClearSave()
	await get_tree().create_timer(4, false).timeout
	print("changing scene to: main")
	get_tree().change_scene_to_file("res://mods-unpacked/GlitchedData-MultiPlayer/scenes/main.tscn")