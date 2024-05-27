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
		'CrtManager',
		'DealerIntelligence',
		'DeathManager',
		'DialogueManager',
		'HandManager',
		'InteractionManager',
		'IntroManager',
		'ItemInteraction',
		'ItemManager',
		'MedicineManager',
		'RoundManager',
		'ShotgunShooting',
	]
	for extension in extensions:
		ModLoaderMod.install_script_extension(extensions_dir_path+extension+".gd")


var fixed = false
var repeated = false
var scene
	
func _process(delta):
	scene = GlobalVariables.get_current_scene_node()
	if not fixed:
		fixed = true
		var root = get_tree().root
		var manager = MultiplayerManager.new()
		manager.name = "MultiplayerManager"
		root.add_child(manager)
		root.move_child(scene, root.get_child_count()-2)

		var multiplayerRoundManager = MultiplayerRoundManager.new()
		multiplayerRoundManager.name = "MultiplayerRoundManager"
		manager.add_child(multiplayerRoundManager)
		
	if scene.name == "menu" && !repeated:
		var logo = scene.get_node("title")
		var logoMat = logo.get_active_material(0)
		var image = Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/MultiPlayer.png")
		var texture = ImageTexture.create_from_image(image)
		logoMat.albedo_texture = texture
		logo.mesh.surface_set_material(0,logoMat)
		repeated = true
