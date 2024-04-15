extends Node

const MODPACK_LOG := "GlitchedData-MultiPlayer:Main"
const MultiplayerManager = preload("utils/MultiplayerManager.gd")

var mod_dir_path := ""
var patches_dir_path := ""

var patches := {}
var last_scene := ""

func _init() -> void:
	mod_dir_path = "res://mods-unpacked/GlitchedData-MultiPlayer/"
	add_patches()
	
func add_patches() -> void:
	pass
	
func _ready() -> void:
	ModLoaderLog.info("Mod Ready!", MODPACK_LOG)
	
func _process(delta):
	var scene := get_scene_root()
	var repeated = (last_scene == scene.name)
	last_scene = scene.name
	if (!repeated):
		ModLoaderLog.debug("Scene loaded: " + last_scene, MODPACK_LOG)
		if last_scene == "menu":
			get_tree().root.add_child(MultiplayerManager.new(), true)
			get_tree().root.get_node("Node").name = "MultiplayerManager"
			var manager = get_tree().root.get_node("MultiplayerManager")
			get_tree().root.move_child(manager, 5)
			
func get_scene_root() -> Node:
	return get_tree().get_root().get_child(5)
