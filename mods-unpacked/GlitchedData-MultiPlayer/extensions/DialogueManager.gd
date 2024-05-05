extends "res://scripts/DialogueManager.gd"

func ShowText_ForDuration(activeText : String, showDuration : float):
	await get_tree().create_timer(showDuration, false).timeout

func ShowText_Forever(activeText : String):
	pass

func ShowText_Phone(activeText : String):
	if (scaling): 
		dialogueUI_backdrop.scale = Vector2(17.209, dialogueUI_backdrop.scale.y)
	else: dialogueUI_backdrop.scale = origscale_backdrop
	
	looping = false
	dialogueUI.visible_characters = 0
	dialogueUI.text = activeText
	dialogueUI.visible = true
	dialogueUI_backdrop.visible = true
	looping = true
	TickText()
	scaling = false