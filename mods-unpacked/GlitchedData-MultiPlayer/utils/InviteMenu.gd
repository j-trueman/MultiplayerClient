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
@export var userListLeaderboard : VBoxContainer
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
@export var onlinePlayers : Label
@export var chat_parent : Control
@export var chat_array : Array[Label]
@export var chat_background : ColorRect
@export var chat_input : LineEdit

signal serverInviteList(invites)
signal connectionSuccess

var popupInvite
var inviteShowQueue = []
var multiplayerManager
var mrm
var cursorManager
var interactionManager
var menuIsVisible = false
var selectedInput
var inputText = ""
var inputColumn = 0
var lefting = false
var righting = false
var backspacing = false
var deleting = false
var moveTimer
var canMove = true
var chatTimer_array = [10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0]
var chatTimer = true
var markForFocus = false
var popupVisible = false
var deniedUsers = []
var blockedUsers = []
var playerListRefreshTimer = 0.0
var currentUserList = {}
var score = 0

signal inviteFinished

func _ready():
	cursorManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	mrm = get_tree().root.get_node("MultiplayerManager/MultiplayerRoundManager")
	mrm.opponent = ""
	multiplayerManager.inviteMenu = self
	multiplayerManager.loginStatus.connect(processLoginStatus)
	multiplayerManager.opponentActive = false
	menuButton.button_down.connect(toggleMenu)
	signupButton.button_down.connect(requestUsername)
	incomingButton.button_down.connect(func(): updateInviteList("incoming", false))
	outgoingButton.button_down.connect(func(): updateInviteList("outgoing", false))

	var blockedUsersFile = FileAccess.open("user://blockedusers.json", FileAccess.READ)
	var blockedUsersVar = blockedUsersFile.get_var(true)
	if blockedUsersVar is Array:
		blockedUsers = blockedUsersVar
	blockedUsersFile.close()

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

	chat_parent.visible = multiplayerManager.chat_enabled
	selectedInput = usernameInput
	chat_input.text_changed.connect(onChatEdit)
	chat_input.text_changed.connect(onTextEdit)
	usernameInput.text_changed.connect(onTextEdit)

func _process(delta):
	if multiplayerManager.loggedIn and multiplayerManager.crtManager.viewing and userList.visible:
		playerListRefreshTimer += delta
		if playerListRefreshTimer >= 0.5:
			playerListRefreshTimer = 0.0
			multiplayerManager.requestPlayerList.rpc()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and multiplayerManager.loggedIn and not ((multiplayerManager.inMatch and mrm.opponent != "DEALER") or multiplayerManager.inCredits):
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

	if canMove and moveTimer > 0.45 and lefting and selectedInput.caret_column > 0:
		selectedInput.caret_column -= 1
	if canMove and moveTimer > 0.45 and righting and selectedInput.caret_column < selectedInput.text.length():
		selectedInput.caret_column += 1
	if canMove and backspacing and selectedInput.caret_column > 0:
		selectedInput.delete_char_at_caret()
	if canMove and deleting and selectedInput.caret_column < selectedInput.text.length():
		selectedInput.caret_column += 1
		selectedInput.delete_char_at_caret()
	if lefting or righting or backspacing or deleting:
		moveTimer += delta
	if moveTimer > 0 and moveTimer <= 0.45:
		canMove = false
	if moveTimer > 0.45:
		canMove = !canMove
	if chatTimer:
		for i in range(10):
			if chatTimer_array[i] < 10.0: chatTimer_array[i] += delta
			if chatTimer_array[i] > 10.0: chatTimer_array[i] = 10.0
			if chatTimer_array[i] >= 7.0: chat_array[i].modulate.a = (10.0 - chatTimer_array[i])/3.0
	if markForFocus:
		markForFocus = false
		chat_input.grab_focus()
	
func _input(event):
	if multiplayerManager.chat_enabled and multiplayerManager.opponentActive and not multiplayerManager.openedBriefcase:
		if (event.is_action_pressed("mp_chat") and chatTimer):
			chatTimer = false
			chat_background.visible = multiplayerManager.chat_enabled
			chat_input.visible = multiplayerManager.chat_enabled
			for i in range(10):
				if chat_array[i].text != "":
					if chatTimer_array[i] > 7.0: chatTimer_array[i] = 7.0
					chat_array[i].modulate.a = 1.0
			markForFocus = true
		if (event.is_action_pressed("ui_accept") and not chatTimer):
			if not chat_input.text.is_empty():
				sendChat(chat_input.text)
				chat_input.text = ""
			chatTimer = true
			chat_background.visible = false
			chat_input.visible = false
		if (event.is_action_pressed("exit game") and not chatTimer):
			chat_input.text = ""
			chatTimer = true
			chat_background.visible = false
			chat_input.visible = false
	if signupSection.visible or not chatTimer:
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
			if not chatTimer and chat_input.caret_column > 0:
				chat_input.caret_column -= 1
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
			if not chatTimer and chat_input.caret_column < chat_input.text.length():
				chat_input.caret_column += 1
		if (event.is_action_released("ui_right")):
			moveTimer = 0.0
			righting = false

func acceptSavedInvite():
	if not multiplayerManager.savedInvite.is_empty():
		multiplayerManager.crtManager.intro.intbranch_crt.interactionInvalid = true
		await updateInviteList("incoming", false)
		var found = false
		for invite in inviteList.get_children():
			if invite.inviteFromUsername == multiplayerManager.savedInvite:
				found = true
				invite.acceptPressed()
				break
		if not found:
			print("SAVED INVITE NOT FOUND. RESETTING")
			multiplayerManager.savedInvite = ""
			GlobalVariables.get_current_scene_node().get_node("standalone managers/reset manager").Reset()

func requestUsername():
	multiplayerManager.connectToServer()
	await multiplayer.connected_to_server
	multiplayerManager.requestNewUser.rpc(usernameInput.text)

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
	if deniedUsers.has(fromUsername) or blockedUsers.has(fromUsername):
		multiplayerManager.denyInvite.rpc(fromID)
	else:
		inviteShowQueue.push_back(fromID)
		print(inviteShowQueue.find(fromID))
		if inviteShowQueue.find(fromID) > 0:
			while inviteShowQueue.find(fromID) != 0:
				await inviteFinished
		popupInvite = load("res://mods-unpacked/GlitchedData-MultiPlayer/components/invite.tscn").instantiate()
		popupInvite.setup(fromUsername, fromID, self)
		popupSection.add_child(popupInvite)
		var newMenuInvite = load("res://mods-unpacked/GlitchedData-MultiPlayer/components/invite.tscn").instantiate()
		newMenuInvite.setup(fromUsername, fromID, self)
		newMenuInvite.isInMenu = true
		inviteList.add_child(newMenuInvite)
		print(popupInvite)
		popupInvite.animationPlayer.play("progress")
		popupVisible = true

func removeInvite(from):
	for invite in inviteList.get_children():
		if invite.inviteFromID == from:
			invite.queue_free()
	for invite in popupSection.get_children():
		if invite.inviteFromID == from:
			invite.queue_free()

func showReady(username):
	multiplayerManager.crtManager.intro.dealerName.text = username.to_upper()
	mrm.opponent = username.to_upper()
	setupMatch()
	gameReadySection.visible = true
	opponentUsernameLabel.text = username
	timerAccept.play("countdown")
	
func showJoin():
	setupMatch()
	joiningGameSection.visible = true
	timerJoin.play("countdown")

func setupMatch():
	firstChatMessage()
	multiplayerManager.opponentActive = true
	multiplayerManager.openedBriefcase = false
	multiplayerManager.crtManager.viewing = false
	multiplayerManager.crtManager.branch_exit.interactionAllowed = false
	multiplayerManager.crtManager.intro.intbranch_crt.interactionAllowed = false
	inputText = ""
	inputColumn = 0
	selectedInput = chat_input
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

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
	score = list[multiplayer.get_unique_id()].score
	list.erase(multiplayer.get_unique_id())
	var users = userList.get_children()
	for userObject in users:
		if list.get(userObject.userID) == null:
			userObject.queue_free()
			currentUserList.erase(userObject.userID)
		else:
			userObject.setStatus(true if userObject.username == mrm.opponent else list[userObject.userID].status)
			userObject.stylizeScore(list[userObject.userID].score)
	var needToSort = false
	for user in list:
		var username = list[user].username
		var userStatus = list[user].status
		var inList = currentUserList.get(user)	# No idea why this needs to be on a separate line but whatever
		if (inList != null) or blockedUsers.has(username): continue
		needToSort = true
		currentUserList[user] = list[user]
		var newUserItem = load('res://mods-unpacked/GlitchedData-MultiPlayer/components/user.tscn').instantiate()
		newUserItem.setStatus(userStatus)
		newUserItem.stylizeScore(list[user].score)
		var hasInvite = false
		for invite in inviteList:
			if invite.find_key("id") == user:
				hasInvite = true
				break
		newUserItem.setup(username, user, multiplayerManager, hasInvite)
		userList.add_child(newUserItem)
	if needToSort:
		users = userList.get_children()
		users.sort_custom(
			func(a: Node, b: Node):	return (a.username == "dealer" or a.username < b.username) and not b.username == "dealer"
		)
		for i in range(users.size()): userList.move_child(users[i], i)
	if userList.visible: stylizePlayerListHeader()
		
func processLoginStatus(reason):
	multiplayerManager.rpcMismatch = false
	if reason == "success":
		title.text = "WELCOME, " + multiplayerManager.accountName.to_upper()
		underline.text = "-------- "
		for i in range(multiplayerManager.accountName.length()): underline.text += "-"
		crtMenu.visible = true
		playerListSection.visible = true
		signupSection.visible = false
		usernameInput.release_focus()
		multiplayerManager.requestPlayerList.rpc()
		multiplayerManager.requestLeaderboard.rpc()
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
			"outdatedClient":
				errorLabel.text = "OUTDATED CLIENT! PLEASE UPDATE\nAT BUCKSHOTMULTIPLAYER.NET"
				print("OUTDATED CLIENT")
		usernameInput.grab_focus()
	errorClear()
	signupSection.visible = true

func errorClear():
	if errorLabel.text != "":
		await get_tree().create_timer(10, false).timeout
		errorLabel.text = ""

func sendChat(message):
	multiplayerManager.sendChat.rpc(message)
	addChatMessage(message, true)

func addChatMessage(message, isPlayer):
	for i in range(9):
		chat_array[i].text = chat_array[i + 1].text
		chat_array[i].modulate.a = chat_array[i + 1].modulate.a
		chatTimer_array[i] = chatTimer_array[i + 1]
	var sender = multiplayerManager.accountName.to_upper() if isPlayer else mrm.opponent
	chat_array[9].text = "<" + sender + "> " + message
	chat_array[9].modulate.a = 1.0
	chatTimer_array[9] = 0.0

func firstChatMessage():
	var message
	if mrm.opponent == "DEALER":
		message = "You are now connected with the Dealer. Press T to chat. Messages may be saved."
	else:
		message = "You are now connected with " + mrm.opponent + ". Press T to chat."
	chat_array[9].text = message
	chat_array[9].modulate.a = 1.0
	chatTimer_array[9] = 0.0

func onChatEdit(text):
	var column = chat_input.caret_column
	chat_input.size.x = 0
	if chat_input.size.x >= 523:
		chat_input.max_length = chat_input.text.length()
	else:
		chat_input.max_length = 0
	chat_input.caret_column = column

func onTextEdit(input):
	if multiplayerManager.isValidString(input):
		inputText = selectedInput.text
		inputColumn = selectedInput.caret_column
	else:
		selectedInput.text = inputText
		selectedInput.caret_column = inputColumn

func blockUser(username):
	blockedUsers.append(username)
	for user in userList.get_children():
		if user.username == username:
			user.queue_free()
			break
	for user in userListLeaderboard.get_children():
		if user.username == username:
			user.queue_free()
			break
	var blockedUsersFile = FileAccess.open("user://blockedusers.json", FileAccess.WRITE)
	blockedUsersFile.store_var(blockedUsers,true)
	blockedUsersFile.close()

func removePopup():
	popupInvite.animationPlayer.stop()
	popupInvite.acceptButton.visible = false
	popupInvite.denyButton.visible = false
	popupInvite.destroy(null)

func toggleLeaderboard():
	if userList.visible:
		var scoreStr = longScore(score)
		var spacer = ""
		for i in (26 - scoreStr.length()): spacer += " "
		onlinePlayers.text = ("LEADERBOARD" + spacer) + "$" + scoreStr
		userList.visible = false
		userListLeaderboard.visible = true
		multiplayerManager.requestLeaderboard.rpc()
	elif userListLeaderboard.visible:
		stylizePlayerListHeader()
		userList.visible = true
		userListLeaderboard.visible = false
		multiplayerManager.requestPlayerList.rpc()

func receiveLeaderboard(list):
	for user in userListLeaderboard.get_children():
		user.queue_free()
	for user in list:
		var username = user.username
		if blockedUsers.has(username): continue
		var newUserItem = load('res://mods-unpacked/GlitchedData-MultiPlayer/components/user_leaderboard.tscn').instantiate()
		newUserItem.setup(username, multiplayerManager, "$" + longScore(user.score))
		userListLeaderboard.add_child(newUserItem)
		if username == multiplayerManager.accountName:
			newUserItem.disconnectUsername()

func longScore(score):
	var scoreStr = str(score * 1000)
	var len = scoreStr.length()
	for i in len-1:
		if (i+1) % 3 == 0:
			scoreStr = scoreStr.insert(len-i-1,",")
	return scoreStr

func rpcMismatch():
	signupSection.visible = true
	usernameInput.visible = false
	signupButton.visible = false
	crtMenu.visible = true
	errorLabel.text = "OUTDATED CLIENT! PLEASE UPDATE\nAT BUCKSHOTMULTIPLAYER.NET"

func stylizePlayerListHeader():
	var scoreStr = longScore(score)
	var spacer = ""
	for i in (20 - scoreStr.length() - str(currentUserList.size()).length()): spacer += " "
	onlinePlayers.text = "ONLINE PLAYERS (" + str(currentUserList.size()) + ")" + spacer + "$" + scoreStr