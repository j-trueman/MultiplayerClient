extends Node

@export var screenparent_players : Node3D
@export var screenparent_invite : Sprite3D
@export var screenparent_login : Node3D

@export var options_players : Array[Label3D]
@export var options_players_visible : int = 0
@export var options_invite : Array[Label3D]
@export var options_login : Array[SpriteBase3D]

@export var username_input : InputBox
@export var error_label : Label3D
@export var invitee_label : Label3D

var options_index = 0
