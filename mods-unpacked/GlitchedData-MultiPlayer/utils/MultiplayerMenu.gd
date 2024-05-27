extends Node

@export var screenparent_players : Node3D
@export var screenparent_invite : Sprite3D
@export var screenparent_login : Node3D
@export var screenparent_ready : Sprite3D

@export var options_players : Array[Label3D]
@export var options_players_visible : int = 0
@export var options_invite : Array[Label3D]
@export var options_login : Array[Label3D]

@export var error_label : Label3D
@export var error_label_players : Label3D
@export var invitee_label : Label3D

@export var ready_username : Label3D
@export var ready_opponent : Label3D

var options_index = 0
var username_input

func _ready():
	username_input = get_parent().get_node("crt screen_multiplayer login/username_inputbox/InputBox")
