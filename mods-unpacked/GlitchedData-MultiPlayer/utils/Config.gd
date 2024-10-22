extends Node

@export var url : LineEdit
@export var chat : CheckBox
@export var voice : CheckBox

const AUTHORNAME_MODNAME_DIR := "GlitchedData-MultiPlayer"

var multiplayermanager
var lefting = false
var righting = false
var backspacing = false
var deleting = false
var moveTimer
var canMove = true
var returnButton

func _ready():
	multiplayermanager = get_tree().get_root().get_node("MultiplayerManager")
	url.text_changed.connect(updateURL)
	url.text = multiplayermanager.url
	url.caret_column = url.text.length()
	chat.button_pressed = multiplayermanager.chat_enabled
	voice.button_pressed = multiplayermanager.voice_enabled

	returnButton = GlobalVariables.get_current_scene_node().get_node("Camera/dialogue UI/menu ui/mods/true button_mods return")
	returnButton.focus_mode = 0
	url.grab_focus()

func _exit_tree():
	returnButton.focus_mode = 2
	multiplayermanager.chat_enabled = chat.button_pressed
	multiplayermanager.voice_enabled = voice.button_pressed

	ModLoaderStore.mod_data[AUTHORNAME_MODNAME_DIR].load_configs()
	var config_object = ModLoaderConfig.get_config(AUTHORNAME_MODNAME_DIR, multiplayermanager.keyLocation)
	if (config_object != null):
		config_object.data.url = multiplayermanager.url
		config_object.data.chat_enabled = multiplayermanager.chat_enabled
		config_object.data.voice_enabled = multiplayermanager.voice_enabled
		ModLoaderConfig.update_config(config_object)


func _process(delta):
	if url.has_focus() and canMove:
		if lefting and url.caret_column > 0:
			url.caret_column -= 1
		if righting and url.caret_column < url.text.length():
			url.caret_column += 1
		if backspacing and url.caret_column > 0:
			url.delete_char_at_caret()
		if deleting and url.caret_column < url.text.length():
			url.caret_column += 1
			url.delete_char_at_caret()
	if lefting or righting or backspacing or deleting:
		moveTimer += delta
	if moveTimer > 0 and moveTimer <= 0.45:
		canMove = false
	if moveTimer > 0.45:
		canMove = !canMove

func _input(event):
	if (event.is_action_pressed("ui_left")):
		canMove = true
		moveTimer = 0.0
		righting = false
		backspacing = false
		deleting = false
		lefting = true
	if (event.is_action_released("ui_left")):
		moveTimer = 0.0
		lefting = false
	if (event.is_action_pressed("ui_right")):
		canMove = true
		moveTimer = 0.0
		lefting = false
		backspacing = false
		deleting = false
		righting = true
	if (event.is_action_released("ui_right")):
		moveTimer = 0.0
		righting = false
	if (event.is_action_pressed("ui_cancel")):
		canMove = true
		moveTimer = 0.0
		lefting = false
		righting = false
		deleting = false
		backspacing = true
	if (event.is_action_released("ui_cancel")):
		moveTimer = 0.0
		backspacing = false
	if (event.is_action_pressed("mp_delete")):
		canMove = true
		moveTimer = 0.0
		lefting = false
		righting = false
		backspacing = false
		deleting = true
	if (event.is_action_released("mp_delete")):
		moveTimer = 0.0
		deleting = false

func updateURL(text):
	multiplayermanager.url = text.to_lower()
	