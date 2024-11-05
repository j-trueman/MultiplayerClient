extends Node

const ControllerManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/ControllerManager.gd")
const CursorManager = preload("res://mods-unpacked/GlitchedData-MultiPlayer/scripts/CursorManager.gd")

@export var controller : ControllerManager
@export var cursor : CursorManager
@export var anim : AnimationPlayer
@export var label : Label
var exitAllowed = false
var total = 0

func ShowUI():
	var bind
	var bind_keyboard
	var bind_controller
	var events = InputMap.action_get_events("exit game")
	bind_keyboard = events[0].as_text()
	bind_controller = events[1].as_text()
	var firstindex = bind_controller.rfind("(")
	bind_keyboard = bind_keyboard.trim_suffix("(Physical)")
	bind_keyboard = bind_keyboard.replace(" ", "")
	bind_controller = bind_controller.left(firstindex)
	if (cursor.controller_active): bind = str(bind_controller)
	else: bind = str(bind_keyboard)
	label.text = tr("HOLD TO EXIT") % str(bind)
	anim.play("RESET")
	anim.play("fade out")

func CheckExit():
	if (total > 2 && exitAllowed):
		ExitGame()
		exitAllowed = false

var multiplayerManager
var mrm

func _ready():
	await get_tree().create_timer(.5, false).timeout
	exitAllowed = true
	multiplayerManager = get_tree().get_root().get_node("MultiplayerManager")
	mrm = multiplayerManager.get_node("MultiplayerRoundManager")
	mrm.exit = self

func ExitGame():
	multiplayer.multiplayer_peer = null
	multiplayerManager.loggedIn = false
	multiplayerManager.inMatch = false
	print("changing scene to: menu")
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(delta):
	if exitAllowed:
		if (Input.is_action_just_pressed("exit game") and multiplayerManager.inviteMenu.chatTimer):
			ShowUI()
		if Input.is_action_pressed("exit game"):
			total += delta
	if Input.is_action_just_released("exit game"):
		total = 0
	CheckExit()

