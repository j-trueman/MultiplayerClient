extends PanelContainer

@onready var mod_list_container = $MarginContainer/PanelContainer/VBoxContainer2/ScrollContainer/VBoxContainer
# Called when the node enters the scene tree for the first time.
func _ready():
	for mod in ModLoaderMod.get_mod_data_all().values():
		var mname = mod.manifest["name"]
		var author = mod.manifest["mod_namespace"]
		var version = mod.manifest["version_number"]
		var description = mod.manifest["description"]
		var panel = load("res://mod-loader-assets/mod_panel.tscn").instantiate()
		var path = ModLoaderMod.get_unpacked_dir()+"/"+author+"-"+mname
		panel.mod_name = mname
		panel.mod_author = author
		panel.mod_version = version
		panel.mod_description = description
		panel.mod_path = path
		mod_list_container.add_child(panel)
