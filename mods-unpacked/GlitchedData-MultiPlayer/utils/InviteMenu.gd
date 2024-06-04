extends Control

@export var inviteContainer : ScrollContainer
@export var inviteList : VBoxContainer
@export var popupSection : Control
@export var playerListSection : Control
@export var signupSection : Control
@export var menuButton : Button
@export var incomingButton : Button
@export var outgoingButton : Button
@export var buttonHighlightAnimator : AnimationPlayer
@export var crtMenu : Panel
@export var userList : VBoxContainer
@export var usernameInput : LineEdit
@export var signupButton : Button
@export var opponentUsernameLabel : Label
@export var gameReadySection : Control
@export var joiningGameSection : Control
@export var timerAccept : AnimationPlayer
@export var timerJoin : AnimationPlayer
@export var errorLabel : Label
@export var title : Label
@export var underline : Label

signal serverInviteList(invites)
signal connectionSuccess

var inviteShowQueue = []
var multiplayerManager
var cursorManager
var interactionManager
var menuIsVisible = false
var lefting = false
var righting = false
var backspacing = false
var deleting = false
var moveTimer
var canMove = true

signal inviteFinished

func _ready():
	cursorManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	multiplayerManager.inviteMenu = self
	multiplayerManager.loginStatus.connect(processLoginStatus)
	menuButton.button_down.connect(toggleMenu)
	signupButton.button_down.connect(func(): 
		multiplayerManager.connectToServer()
		await multiplayer.connected_to_server
		multiplayerManager.requestNewUser.rpc(usernameInput.text))
	incomingButton.button_down.connect(func(): updateInviteList("incoming", false))
	outgoingButton.button_down.connect(func(): updateInviteList("outgoing", false))

	cursorManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
	interactionManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/interaction manager")
	var buttons = [menuButton, incomingButton, outgoingButton]
	for button_toConnect in buttons:
		button_toConnect.focus_entered.connect(func(): setCursorImage("hover"))
		button_toConnect.mouse_entered.connect(func(): setCursorImage("hover"))
		button_toConnect.focus_exited.connect(func(): setCursorImage("point"))
		button_toConnect.mouse_exited.connect(func(): setCursorImage("point"))

	var menuTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/burger.png"))
	menuButton.set_button_icon(menuTexture)

func _process(delta):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and multiplayerManager.loggedIn and not multiplayerManager.inMatch:
		menuButton.visible = true
		if menuIsVisible:
			inviteContainer.visible = true
			incomingButton.visible = true
			outgoingButton.visible = true
			buttonHighlightAnimator.get_parent().visible = true
	else:
		menuButton.visible = false
		inviteContainer.visible = false
		incomingButton.visible = false
		outgoingButton.visible = false
		buttonHighlightAnimator.get_parent().visible = false

	if canMove and moveTimer > 0.45 and lefting and usernameInput.caret_column > 0:
		usernameInput.caret_column -= 1
	if canMove and moveTimer > 0.45 and righting and usernameInput.caret_column < usernameInput.text.length():
		usernameInput.caret_column += 1
	if canMove and backspacing and usernameInput.caret_column > 0:
		usernameInput.delete_char_at_caret()
	if canMove and deleting and usernameInput.caret_column < usernameInput.text.length():
		usernameInput.caret_column += 1
		usernameInput.delete_char_at_caret()
	if lefting or righting or backspacing or deleting:
		moveTimer += get_process_delta_time()
	if moveTimer > 0 and moveTimer <= 0.45:
		canMove = false
	if moveTimer > 0.45:
		canMove = !canMove

func _input(event):
	if signupSection.visible:
		if (event.is_action_pressed("ui_cancel")):
			canMove = true
			moveTimer = 0.0
			lefting = false
			righting = false
			deleting = false
			backspacing = true
		if (event.is_action_released("ui_cancel")):
			moveTimer = 0.0
			backspacing = false
		if (event.is_action_pressed("mp_delete")):
			canMove = true
			moveTimer = 0.0
			lefting = false
			righting = false
			backspacing = false
			deleting = true
		if (event.is_action_released("mp_delete")):
			moveTimer = 0.0
			deleting = false
		if (event.is_action_pressed("ui_left")):
			canMove = true
			moveTimer = 0.0
			righting = false
			backspacing = false
			deleting = false
			lefting = true
		if (event.is_action_released("ui_left")):
			moveTimer = 0.0
			lefting = false
		if (event.is_action_pressed("ui_right")):
			canMove = true
			moveTimer = 0.0
			lefting = false
			backspacing = false
			deleting = false
			righting = true
		if (event.is_action_released("ui_right")):
			moveTimer = 0.0
			righting = false

func setCursorImage(alias):
	match alias:
		"hover": interactionManager.checking = false
		"point": interactionManager.checking = true
	cursorManager.SetCursorImage(alias)

func toggleMenu():
	if menuIsVisible:
		menuIsVisible = false
		inviteContainer.visible = false
		incomingButton.visible = false
		outgoingButton.visible = false
		buttonHighlightAnimator.get_parent().visible = false
	else:
		menuIsVisible = true
		inviteContainer.visible = true
		incomingButton.visible = true
		outgoingButton.visible = true
		buttonHighlightAnimator.get_parent().visible = true
		buttonHighlightAnimator.play("RESET")
		updateInviteList("incoming", true)

func receiveInvite(fromUsername, fromID):
	inviteShowQueue.push_back(fromID)
	print(inviteShowQueue.find(fromID))
	if inviteShowQueue.find(fromID) > 0:
		while inviteShowQueue.find(fromID) != 0:
			await inviteFinished
			
	var popupInvite = load("res://mods-unpacked/GlitchedData-MultiPlayer/components/invite.tscn").instantiate()
	popupInvite.setup(fromUsername, fromID, self)
	popupSection.add_child(popupInvite)
	if multiplayerManager.inMatch:
		popupInvite.acceptButton.visible = false
		popupInvite.denyButton.visible = false
	print(popupInvite)
	popupInvite.animationPlayer.play("progress")

func removeInvite(from):
	for invite in inviteList.get_children():
		if invite.inviteFromID == from:
			inviteList.remove_child(invite)
	for invite in popupSection.get_children():
		if invite.inviteFromID == from:
			popupSection.remove_child(invite)

func showReady(username):
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	gameReadySection.visible = true
	opponentUsernameLabel.text = username
	timerAccept.play("countdown")
	
func showJoin():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	joiningGameSection.visible = true
	timerJoin.play("countdown")

func updateInviteList(type, reset):
	for invite in inviteList.get_children():
		invite.queue_free()
	var isOutgoing = false
	match type:
		"incoming":
			if not reset: buttonHighlightAnimator.play_backwards("toggle")
			multiplayerManager.getInvites.rpc("incoming")
		"outgoing":
			buttonHighlightAnimator.play("toggle")
			multiplayerManager.getInvites.rpc("outgoing")
			isOutgoing = true
	var list = await serverInviteList
	for invite in list:
		var newMenuInvite = load("res://mods-unpacked/GlitchedData-MultiPlayer/components/invite.tscn").instantiate()
		newMenuInvite.isInMenu = true
		newMenuInvite.setup(invite.find_key("username"), invite.find_key("id"), self, isOutgoing)
		inviteList.add_child(newMenuInvite)
		await get_tree().create_timer(.1, false).timeout
		
func updateUserList(list):
	multiplayerManager.getInvites.rpc("outgoing")
	var inviteList = await serverInviteList
	list.erase(list.find_key(multiplayer.get_unique_id()))
	for user in userList.get_children():
		user.queue_free()
	for user in list:
		var username = user
		var id = list[user]
		var newUserItem = load('res://mods-unpacked/GlitchedData-MultiPlayer/components/user.tscn').instantiate()
		for invite in inviteList:
			if invite.find_key("id") == id:
				newUserItem.setup(username, id, multiplayerManager, true)
				userList.add_child(newUserItem)
				return
		newUserItem.setup(username, id, multiplayerManager, false)
		userList.add_child(newUserItem)
		
func processLoginStatus(reason):
	if reason == "success":
		title.text = "WELCOME, " + multiplayerManager.accountName.to_upper()
		underline.text = "-------- "
		for i in range(multiplayerManager.accountName.length()): underline.text = underline.text + "-"
		crtMenu.visible = true
		playerListSection.visible = true
		signupSection.visible = false
		multiplayerManager.requestPlayerList.rpc()
		return
	else:
		crtMenu.visible = true
		playerListSection.visible = false
		signupSection.visible = true
		match reason:
			"invalidUsername":
				errorLabel.text = "THAT USERNAME IS INVALID"
				print("THAT USERNAME IS INVALID")
			"userAlreadyExists":
				errorLabel.text = "THAT USER ALREADY EXISTS"
				print("THAT USER ALREADY EXISTS")
			"nonExistentUser":
				errorLabel.text = "CAN'T LOGIN TO A \nNONEXISTENT USER"
				print("CAN'T LOGIN TO A \nNONEXISTENT USER")
			"databaseError":
				errorLabel.text = "THERE WAS AN ERROR \nWITH OUR DATABASE"
				print("THERE WAS AN ERROR \nWITH OUR DATABASE")
			"malformedKey":
				errorLabel.text = "YOUR USER KEY IS CORRUPTED"
				print("YOUR USER KEY IS CORRUPTED")
			"invalidCreds":
				errorLabel.text = "PROVIDED KEY DOESN'T MATCH ACCOUNT"
				print("PROVIDED KEY DOESN'T MATCH ACCOUNT")
			"noKey":
				errorLabel.text = "NO USER KEY FOUND"
				print("NO USER KEY FOUND")
		usernameInput.grab_focus()
	errorClear()
	signupSection.visible = true

func errorClear():
	if errorLabel.text != "":
		await get_tree().create_timer(10, false).timeout
		errorLabel.text = ""
