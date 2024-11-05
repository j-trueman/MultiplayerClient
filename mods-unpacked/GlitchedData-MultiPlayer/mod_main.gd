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
		'MenuManager'	# ALL OTHER EXTENSIONS ARE DIRECTLY INCLUDED IN MAIN.TSCN
				# DUE TO LIMITATIONS IN BRML3
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
		root.move_child(scene, root.get_child_count()-1)

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
		logoMat.texture_repeat = false
		logo.mesh.surface_set_material(0,logoMat)
		logo.position.z = 12.127
		logo.scale.x = 0.66
		logo.scale.z = 0.388
