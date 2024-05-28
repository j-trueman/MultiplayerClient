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

func _ready():
	animationPlayer.animation_finished.connect(destroy)
	
	var icon = get_node("Sprite2D")
	var iconTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/profile.png"))
	icon.set_texture(iconTexture)
	
	var tickButton = get_node("accept")
	var tickTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/tick.png"))
	tickButton.set_button_icon(tickTexture)
	
	var crossButton = get_node("decline")
	var crossTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/cross.png"))
	crossButton.set_button_icon(crossTexture)

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
	print(inviteMenu.get_children())
	inviteMenu.multiplayerManager.acceptInvite.rpc(inviteFromID)
	inviteMenu.multiplayerManager.crtManager.intro.roundManager.playerData.playername = inviteMenu.multiplayerManager.accountName.to_upper()
	inviteMenu.multiplayerManager.crtManager.intro.dealerName.text = inviteFromUsername.to_upper()
	self.queue_free()

func denyPressed():
	inviteMenu.multiplayerManager.denyInvite.rpc(inviteFromID)
	self.queue_free()
	
func cancelPressed():
	var to = inviteFromID
	inviteMenu.multiplayerManager.retractInvite.rpc(to)
	self.queue_free()

func destroy(name):
	if !isInMenu:
		animationPlayer.play("leave")
		await animationPlayer.animation_finished
		inviteMenu.inviteShowQueue.erase(inviteFromID)
		inviteMenu.inviteFinished.emit()
		self.queue_free()
