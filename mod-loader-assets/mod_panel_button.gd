extends Button

# Not as bad code, but still needs fixing
@onready var panel = $"../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	print(panel.config_menu)
	if panel.config_menu == "" or panel.config_menu == null:
		queue_free()
	self.get_child(0).cursor = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _pressed():
	GlobalVariables.get_current_scene_node().get_node("standalone managers/menu manager").ModConfigMenu(panel.mod_path+"/"+panel.config_menu,panel.mod_name)
