extends Panel

@export var usernameButton : Button
@export var blockButton : Button
@export var inviteButton : Button
@export var scoreLabel : Label

var username : String
var userID : int
var multiplayerManager
var override = false

func _ready():
	usernameButton.button_down.connect(toggleBlock)
	blockButton.button_down.connect(block)
	inviteButton.button_down.connect(inviteUser)

func setup(user, id, manager, isInvited):
	username = user
	userID = id
	multiplayerManager = manager
	usernameButton.text = username
	if isInvited:
		inviteButton.text = "PENDING"
		inviteButton.disabled = true

func inviteUser():
	for invite in multiplayerManager.inviteMenu.inviteList.get_children():
		if invite.inviteFromUsername == username:
			invite.acceptPressed()
			return
	print("INVITE %s" % username)
	override = true
	inviteButton.text = "PENDING"
	inviteButton.disabled = true
	multiplayerManager.createInvite.rpc(userID)

func toggleBlock():
	if username.to_lower() == "dealer" or blockButton.visible:
		blockButton.visible = false
	else:
		for user in get_parent().get_children():
			user.blockButton.visible = false
		blockButton.visible = true

func setStatus(status):
	if not override:
		inviteButton.disabled = status
		inviteButton.text = "BUSY" if status else "INVITE"

func block():
	multiplayerManager.blockUser(username)

func stylizeScore(score):
	if score > 0:
		var suffix = "K"
		var displayScore = str(score).substr(0,((str(score).length()-1)%3)+1)
		if score >= 1000000000: suffix = "T"
		elif score >= 1000000: suffix = "B"
		elif score >= 1000: suffix = "M"
		if displayScore.length() == 1 and score >= 1000:
			var decimal = str(score).substr(1,1)
			displayScore += "." + decimal
		scoreLabel.text = "$" + displayScore + suffix
		scoreLabel.visible = true
	else:
		scoreLabel.visible = false
		scoreLabel.text = ""