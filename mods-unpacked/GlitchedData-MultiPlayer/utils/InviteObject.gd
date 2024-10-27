extends Panel

@export var typeLabel : Label
@export var usernameLabel : Label
@export var acceptButton : Button
@export var denyButton : Button
@export var animationPlayer : AnimationPlayer

var inviteFromUsername : String
var inviteFromID : int
var isInMenu = false
var inviteMenu
var cursorManager
var interactionManager

func _ready():
	animationPlayer.animation_finished.connect(destroy)
	
	var icon = get_node("Sprite2D")
	var iconTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/profile.png"))
	icon.set_texture(iconTexture)
	
	var tickTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/tick.png"))
	acceptButton.set_button_icon(tickTexture)
	
	var crossTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/cross.png"))
	denyButton.set_button_icon(crossTexture)

	cursorManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/cursor manager")
	interactionManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/interaction manager")
	var buttons = [acceptButton, denyButton]
	for button_toConnect in buttons:
		button_toConnect.focus_entered.connect(func(): setCursorImage("hover"))
		button_toConnect.mouse_entered.connect(func(): setCursorImage("hover"))
		button_toConnect.focus_exited.connect(func(): setCursorImage("point"))
		button_toConnect.mouse_exited.connect(func(): setCursorImage("point"))

func setCursorImage(alias):
	match alias:
		"hover": interactionManager.checking = false
		"point": interactionManager.checking = true
	cursorManager.SetCursorImage(alias)

func setup(username, id, menu, isOutgoing = false):
	inviteFromUsername = username
	inviteFromID = id
	inviteMenu = menu
	usernameLabel.text = username
	if isOutgoing:
		denyButton.button_down.connect(cancelPressed)
		var tickButton = get_node("accept")
		tickButton.visible = false
		typeLabel.text = "INVITE SENT"
		usernameLabel.get_parent().text = "TO: "
		return
	acceptButton.button_down.connect(acceptPressed)
	denyButton.button_down.connect(denyPressed)

func acceptPressed():
	setCursorImage("point")
	if inviteMenu.mrm.opponent == "DEALER":
		inviteMenu.multiplayerManager.savedInvite = inviteFromUsername
		GlobalVariables.get_current_scene_node().get_node("standalone managers/reset manager").Reset(false)
	else:
		inviteMenu.mrm.opponent = inviteFromUsername.to_upper()
		inviteMenu.multiplayerManager.acceptInvite.rpc(inviteFromID)
		inviteMenu.multiplayerManager.crtManager.intro.roundManager.playerData.playername = inviteMenu.multiplayerManager.accountName.to_upper()
		inviteMenu.multiplayerManager.crtManager.intro.dealerName.text = inviteFromUsername.to_upper()
		inviteMenu.inviteShowQueue.erase(inviteFromID)
		inviteMenu.inviteContainer.visible = false
		inviteMenu.incomingButton.visible = false
		inviteMenu.outgoingButton.visible = false
		inviteMenu.buttonHighlightAnimator.get_parent().visible = false
		inviteMenu.removeInvite(inviteFromID)

func denyPressed():
	inviteMenu.deniedUsers.append(inviteFromUsername)
	inviteMenu.multiplayerManager.denyInvite.rpc(inviteFromID)
	inviteMenu.inviteShowQueue.erase(inviteFromID)
	setCursorImage("point")
	inviteMenu.removeInvite(inviteFromID)
	
func cancelPressed():
	inviteMenu.multiplayerManager.retractInvite.rpc(inviteFromID)
	for user in inviteMenu.userList.get_children():
		if user.username == inviteFromUsername:
			user.inviteButton.text = "INVITE"
			user.inviteButton.disabled = false
			break
	setCursorImage("point")
	inviteMenu.removeInvite(inviteFromID)

func destroy(name):
	if !isInMenu:
		animationPlayer.play("leave")
		await animationPlayer.animation_finished
		inviteMenu.inviteShowQueue.erase(inviteFromID)
		inviteMenu.inviteFinished.emit()
		inviteMenu.popupVisible = false
		setCursorImage("point")
		queue_free()
