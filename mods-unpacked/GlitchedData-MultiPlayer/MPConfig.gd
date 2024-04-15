extends Node

@export var loggedInStatusLabel : Label
@export var usernameInput : LineEdit
@export var createUserButton : Button
@export var errorLabel : Label
var multimanager
var keygenUtil

# Called when the node enters the scene tree for the first time.
func _ready():
	createUserButton.pressed.connect(createUserAccount)
	multimanager = get_tree().root.get_node("MultiplayerManager")
	keygenUtil = get_tree().root.get_node("KeygenUtil")

func createUserAccount():
	var username = usernameInput.text
	var signature = keygenUtil.KeyGen()
	if !signature:
		print("YOU ALREADY HAVE AN ACCOUNT")
		errorLabel.text += "ERROR: YOU ALREADY HAVE AN ACCOUNT\n"
		return false
	if !multimanager.loggedIn:
		multimanager.connectToServer()
		await multiplayer.connected_to_server
		multimanager.createNewMultiplayerUser.rpc(username, signature)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	loggedInStatusLabel.text = str(multimanager.loggedIn)
