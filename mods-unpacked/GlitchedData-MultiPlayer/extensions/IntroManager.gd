extends "res://scripts/IntroManager.gd"

var dealerName

func _ready():
	parent_pills.visible = false
	allowingPills = false
	SetControllerState()
	await get_tree().create_timer(.5, false).timeout
	MainBathroomStart()
	crtManager.SetCRT(true)
	intbranch_crt.interactionAllowed = true
	GlobalVariables.get_current_scene_node().get_node("intro parent/bathroom door/interaction branch_bathroom door").interactionInvalid = true
	
	var multiplayerMenu = load("res://mods-unpacked/GlitchedData-MultiPlayer/CRTMenu.tscn").instantiate()
	multiplayerMenu.name = "crt screen_multiplayer"
	var crtScreen = GlobalVariables.get_current_scene_node().get_node("restroom_CLUB/bathroom wall main_crt hole/crt main parent/crt screen main")
	crtScreen.add_child(multiplayerMenu)
	GlobalVariables.get_current_scene_node().get_node("standalone managers/crt manager").screenparent_multiplayer = multiplayerMenu

	var healthCounterUI = GlobalVariables.get_current_scene_node().get_node("tabletop parent/main tabletop/health counter/health counter ui parent")
	healthCounterUI.get_node("health UI_dealer side/lines2").position.x = 0
	healthCounterUI.get_node("health UI_player side/lines4").position.x = 0
	dealerName = healthCounterUI.get_node("health UI_dealer side/text_dealer")
	dealerName.scale = Vector3(0.334,0.331,0.374)
	dealerName.position.y = 0.676
