extends "res://scripts/IntroManager.gd"

func _ready():
	parent_pills.visible = false
	allowingPills = false
	SetControllerState()
	await get_tree().create_timer(.5, false).timeout
	if (roundManager.playerData.playerEnteringFromDeath && !roundManager.playerData.enteringFromTrueDeath):
		RevivalBathroomStart()
	else:
		MainBathroomStart()
	if (roundManager.playerData.playerEnteringFromDeath or roundManager.playerData.enteringFromTrueDeath): 
		parent_pills.visible = false
		allowingPills = false
	if (!roundManager.playerData.playerEnteringFromDeath && !roundManager.playerData.enteringFromTrueDeath):
		if (FileAccess.file_exists(unlocker.savepath)):
			parent_pills.visible = true
			crtManager.SetCRT(true)
			allowingPills = true
	parent_pills.visible = true
	crtManager.SetCRT(true)
	allowingPills = true
