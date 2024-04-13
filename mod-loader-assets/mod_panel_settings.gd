extends MarginContainer

@export var mod_name : String
@export var mod_author : String
@export var mod_version : String
@export var mod_description : String
@onready var name_label : Label = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Name
@onready var version_label : Label = $MarginContainer/HBoxContainer/VBoxContainer/Version
@onready var description_label : Label = $MarginContainer/HBoxContainer/VBoxContainer/Description
var mod_path : String = "res:/"
@export var config_menu = "ModConfig.tscn"
# Called when the node enters the scene tree for the first time.

func _enter_tree():
	if (!ResourceLoader.exists(mod_path+"/"+config_menu)):
		config_menu=""

func _ready():
	name_label.text = mod_name + " - BY " + mod_author
	version_label.text = "V"+mod_version
	description_label.text = str(mod_description)
