extends Panel

@export var usernameButton : Button
@export var blockButton : Button
@export var scoreLabel : Label

var username : String
var multiplayerManager
var score : String

func _ready():
	usernameButton.button_down.connect(toggleBlock)
	blockButton.button_down.connect(block)

func disconnectUsername():
	usernameButton.button_down.disconnect(toggleBlock)

func setup(user, manager, score):
	username = user
	multiplayerManager = manager
	usernameButton.text = username
	scoreLabel.text = score

func toggleBlock():
	if username.to_lower() == "dealer" or blockButton.visible:
		blockButton.visible = false
	else:
		for user in get_parent().get_children():
			user.blockButton.visible = false
		blockButton.visible = true

func block():
	multiplayerManager.blockUser(username)