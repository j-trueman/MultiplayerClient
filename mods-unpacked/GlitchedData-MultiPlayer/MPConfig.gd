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
	multimanager.errorLabel = errorLabel

func createUserAccount():
	var username = usernameInput.text
	if username == "":
		print("NO USERNAME SET")
		errorLabel.text += "ERROR: YOU DID NOT SET A USERNAME\n"
	var keyFile = multimanager.checkForUserKey()
	if keyFile:
		print("YOU ALREADY HAVE AN ACCOUNT")
		errorLabel.text += "ERROR: YOU ALREADY HAVE AN ACCOUNT\n"
		return false
	if !multimanager.loggedIn:
		multimanager.connectToServer()
		await multiplayer.connected_to_server
		multimanager.createNewMultiplayerUser.rpc(username)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if multimanager.loggedIn:
		loggedInStatusLabel.text = "YES"
	loggedInStatusLabel.text = str(multimanager.loggedIn)
