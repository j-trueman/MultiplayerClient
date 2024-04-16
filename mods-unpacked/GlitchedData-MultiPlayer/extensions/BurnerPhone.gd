extends "res://scripts/BurnerPhone.gd"

var info

func SendDialogue():
	var firstpart = ""
	var secondpart = ""
	var fulldia = ""
	if (info != 0):
		if (info < 0): secondpart = tr("BLANKROUND") % ""
		else: secondpart = tr("LIVEROUND") % ""
		match (int(abs(info))):
			1:
				firstpart = tr("SEQUENCE2")
			2:
				firstpart = tr("SEQUENCE3")
			3:
				firstpart = tr("SEQUENCE4")
			4:
				firstpart = tr("SEQUENCE5")
			5:
				firstpart = tr("SEQUENCE6")
			6:
				firstpart = tr("SEQUENCE7")
			7:
				firstpart = tr("SEQUENCE7")
		fulldia = tr(firstpart) + "\n" + "... " + tr(secondpart)
	else: fulldia = tr("UNFORTUNATE")
	dia.ShowText_Forever(fulldia)
	await get_tree().create_timer(3, false).timeout
	dia.HideText()