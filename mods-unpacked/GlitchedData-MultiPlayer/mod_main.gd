extends Node

const AUTHORNAME_MODNAME_DIR := "GlitchedData-MultiPlayer"
const MultiplayerManager = preload("utils/MultiplayerManager.gd")
const MultiplayerRoundManager = preload("utils/MultiplayerRoundManager.gd")

var mod_dir_path := ""
var extensions_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir()+(AUTHORNAME_MODNAME_DIR)+"/"
	# Add extensions
	install_script_extensions()

func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path+"extensions/"
	const extensions = [
		'BurnerPhone',
		'DealerIntelligence',
		'InteractionManager',
		'ItemManager',
		'MedicineManager',
		'RoundManager',
		'ShotgunShooting'
	]
	for extension in extensions:
		ModLoaderMod.install_script_extension(extensions_dir_path+extension+".gd")

var fixed = false
var scene
	
func _process(delta):
	if not fixed:
		fixed = true
		var root = get_tree().get_root()
		var manager = MultiplayerManager.new()
		manager.name = "MultiplayerManager"
		root.add_child(manager)
		scene = GlobalVariables.get_current_scene_node()
		root.move_child(scene, root.get_child_count()-2)

		var multiplayerRoundManager = MultiplayerRoundManager.new()
		multiplayerRoundManager.name = "multiplayer round manager"
		manager.add_child(multiplayerRoundManager)