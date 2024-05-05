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
		'DeathManager',
		'DialogueManager',
		'HandManager',
		'InteractionManager',
		'ItemInteraction',
		'ItemManager',
		'MedicineManager',
		'RoundManager',
		'InteractionManager',
		'ShotgunShooting'
	]
	ModLoaderMod.install_script_extension(extensions_dir_path+"CrtManager.gd")
#	for extension in extensions:
#		ModLoaderMod.install_script_extension(extensions_dir_path+extension+".gd")

var fixed = false
var repeated = false
var scene
	
func _process(delta):
	if GlobalVariables.get_current_scene_node().name == "main" && not repeated:
		repeated = true
		var multiplayerMenu = load(mod_dir_path + "CRTMenu.tscn").instantiate()
		multiplayerMenu.name = "crt screen_multiplayer"
		var crtScreen = GlobalVariables.get_current_scene_node().get_node("restroom_CLUB/bathroom wall main_crt hole/crt main parent/crt screen main")
		crtScreen.add_child(multiplayerMenu)
		GlobalVariables.get_current_scene_node().get_node("standalone managers/crt manager").screenparent_multiplayer = multiplayerMenu
		
	if not fixed:
		fixed = true
		var root = get_tree().root
		var manager = MultiplayerManager.new()
		manager.name = "MultiplayerManager"
		root.add_child(manager)
		scene = GlobalVariables.get_current_scene_node()
		root.move_child(scene, root.get_child_count()-2)

		var multiplayerRoundManager = MultiplayerRoundManager.new()
		multiplayerRoundManager.name = "multiplayer round manager"
		manager.add_child(multiplayerRoundManager)
