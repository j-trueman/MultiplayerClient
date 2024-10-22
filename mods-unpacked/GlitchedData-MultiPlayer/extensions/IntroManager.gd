extends "res://scripts/IntroManager.gd"

var dealerName
var multiplayerManager

func _ready():
	parent_pills.visible = false
	allowingPills = false
	SetControllerState()
	await get_tree().create_timer(.5, false).timeout
	MainBathroomStart()
	crtManager.SetCRT(true)
	intbranch_crt.interactionAllowed = true
	intbranch_bathroomdoor.interactionInvalid = true

	var healthCounterUI = GlobalVariables.get_current_scene_node().get_node("tabletop parent/main tabletop/health counter/health counter ui parent")
	healthCounterUI.get_node("health UI_dealer side/lines2").position.x = 0
	healthCounterUI.get_node("health UI_player side/lines4").position.x = 0
	dealerName = healthCounterUI.get_node("health UI_dealer side/text_dealer")
	dealerName.scale = Vector3(0.334,0.331,0.374)
	dealerName.position.y = 0.676

	multiplayerManager = get_tree().get_root().get_node("MultiplayerManager")
	multiplayerManager.resetManager = GlobalVariables.get_current_scene_node().get_node("standalone managers/reset manager")

func RevertCRT():
	animator_pp.play("brightness fade out")
	#anim_revert.play("revert")
	btn_pillsYes.visible = false
	btn_pillsNo.visible = false
	intbranch_pillyes.interactionAllowed = false
	intbranch_pillno.interactionAllowed = false
	await get_tree().create_timer(2.05, false).timeout
	RestRoomIdle()
	animator_pp.play("brightness fade in")
	anim_pillflicker.play("flicker pill")
	await get_tree().create_timer(.6, false).timeout
	cursor.SetCursor(true, true)
	intbranch_bathroomdoor.interactionAllowed = true
	btn_bathroomdoor.visible = true
	intbranch_crt.interactionAllowed = not multiplayerManager.inMatch
	btn_screen.visible = true
	if (cursor.controller_active): btn_bathroomdoor.grab_focus()
	controller.previousFocus = btn_bathroomdoor