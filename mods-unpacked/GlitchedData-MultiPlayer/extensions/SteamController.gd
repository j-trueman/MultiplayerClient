extends "res://scripts/SteamController.gd"

func steamInit(_var1 = null):
	if configFile == null:
		configFile = ConfigFile.new()
		if configFile.load(configFileName) != OK or configFile.get_sections().is_empty():
			configFile.set_value("multiplayer", "url", url)
			configFile.set_value("multiplayer", "username", username)
			configFile.save(configFileName)
		else:
			url = configFile.get_value("multiplayer", "url")
			username = configFile.get_value("multiplayer", "username")

	var vibeCheck = true
	loggedIn = vibeCheck
	steamID = 0
	GlobalSteam.STEAM_ID = 0
	return {"status": 1, "verbal": "Steamworks active"} if loggedIn \
		else {"status": 20, "verbal": "Steam not running"}