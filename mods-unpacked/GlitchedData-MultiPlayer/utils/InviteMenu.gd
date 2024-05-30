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

signal serverInviteList(invites)

var inviteShowQueue = []
var multiplayerManager
var cursorManager
var interactionManager

signal inviteFinished

func _ready():
	cursorManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	multiplayerManager.inviteMenu = self
	menuButton.button_down.connect(toggleMenu)
	signupButton.button_down.connect(func(): multiplayerManager.requestUserExistsStatus.rpc(usernameInput.text))
	incomingButton.button_down.connect(func(): updateInviteList("incoming"))
	outgoingButton.button_down.connect(func(): updateInviteList("outgoing"))

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
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE && !multiplayerManager.inMatch:
		menuButton.visible = true
		return
	menuButton.visible = false
  
func setCursorImage(alias):
	match alias:
		"hover": interactionManager.checking = false
		"point": interactionManager.checking = true
	cursorManager.SetCursorImage(alias)

func toggleMenu():
	if inviteContainer.visible:
		inviteContainer.visible = false
		incomingButton.visible = false
		outgoingButton.visible = false
		buttonHighlightAnimator.get_parent().visible = false
	else: 
		inviteContainer.visible = true
		incomingButton.visible = true
		outgoingButton.visible = true
		buttonHighlightAnimator.get_parent().visible = true
		updateInviteList("incoming")

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

func updateInviteList(type):
	for invite in inviteList.get_children():
		invite.queue_free()
	var isOutgoing = false
	match type:
		"incoming":
			buttonHighlightAnimator.play_backwards("toggle")
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
		
