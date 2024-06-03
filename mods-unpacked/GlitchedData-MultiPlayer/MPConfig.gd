extends Node
@export var url : LineEdit
var multiplayermanager

func _ready():
	multiplayermanager = get_tree().get_root().get_node("MultiplayerManager")
	url.text_changed.connect(updateURL)
	url.text = multiplayermanager.url

func updateURL(text):
	multiplayermanager.url = text.to_lower()
	