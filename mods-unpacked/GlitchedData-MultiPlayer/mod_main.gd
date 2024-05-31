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
		'UserExit'
	]
	for extension in extensions:
		ModLoaderMod.install_script_extension(extensions_dir_path+extension+".gd")

var injected = false
var scene
	
func _process(delta):
	scene = GlobalVariables.get_current_scene_node()
	if not injected:
		injected = true
		var root = get_tree().root
		
		var manager = MultiplayerManager.new()
		manager.name = "MultiplayerManager"
		root.add_child(manager)
		root.move_child(scene, root.get_child_count()-2)

		var multiplayerRoundManager = MultiplayerRoundManager.new()
		multiplayerRoundManager.name = "MultiplayerRoundManager"
		manager.add_child(multiplayerRoundManager)
		
	if scene.name == "main" && not scene.has_node("fixed"):
		var fixed = Node.new()
		fixed.name = "fixed"
		scene.add_child(fixed)
		
		var inviteMenu = load("res://mods-unpacked/GlitchedData-MultiPlayer/components/InviteMenu.tscn").instantiate()
		inviteMenu.name = "invite menu"
		scene.get_node("Camera/dialogue UI").add_child(inviteMenu)
		
	if scene.name == "menu" && not scene.has_node("fixed"):
		var fixed = Node.new()
		fixed.name = "fixed"
		scene.add_child(fixed)
		var logo = scene.get_node("title")
		var logoMat = logo.get_active_material(0)
		var image = Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/MultiPlayer.png")
		var texture = ImageTexture.create_from_image(image)
		logoMat.albedo_texture = texture
		logo.mesh.surface_set_material(0,logoMat)
