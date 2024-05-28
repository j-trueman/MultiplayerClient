extends Control

var inviteObject = "res://mods-unpacked/GlitchedData-MultiPlayer/invite.tscn"

@export var inviteContainer : ScrollContainer
@export var inviteList : VBoxContainer
@export var popupSection : Control
@export var menuButton : Button
@export var incomingButton : Button
@export var outgoingButton : Button
@export var buttonHighlightAnimator : AnimationPlayer

signal serverInviteList(invites)

var inviteShowQueue = []
var multiplayerManager

signal inviteFinished

func _ready():
	multiplayerManager = get_tree().root.get_node("MultiplayerManager")
	multiplayerManager.inviteMenu = self
	menuButton.button_down.connect(toggleMenu)
	incomingButton.button_down.connect(func(): updateInviteList("incoming"))
	outgoingButton.button_down.connect(func(): updateInviteList("outgoing"))
	
	var menuTexture = ImageTexture.create_from_image(Image.load_from_file("res://mods-unpacked/GlitchedData-MultiPlayer/media/burger.png"))
	menuButton.set_button_icon(menuTexture)

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
			
	var popupInvite = load(inviteObject).instantiate()
	popupInvite.setup(fromUsername, fromID, self)
	popupSection.add_child(popupInvite)
	popupInvite.animationPlayer.play("progress")

func removeInvite(from):
	for invite in inviteList.get_children():
		if invite.inviteFromID == from:
			inviteList.remove_child(invite)
	for invite in popupSection.get_children():
		if invite.inviteFromID == from:
			popupSection.remove_child(invite)
	
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
		var newMenuInvite = load(inviteObject).instantiate()
		newMenuInvite.isInMenu = true
		newMenuInvite.setup(invite.find_key("username"), invite.find_key("id"), self, isOutgoing)
		inviteList.add_child(newMenuInvite)
#		newMenuInvite.animationPlayer.play("menu")
		await get_tree().create_timer(.1, false).timeout
