extends Node

var prefix = "BRML Steam: "

enum {
	LEADERBOARD_DATA_REQUEST_FRIENDS,
	LEADERBOARD_DATA_REQUEST_GLOBAL,
	LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER
}

signal leaderboard_find_result(var1, var2)
signal leaderboard_score_uploaded(var1, var2, var3)
signal leaderboard_scores_downloaded(var1, var2, var3)

func clearAchievement(var1):
	print(prefix + "Cleared achievement")
	return false

func downloadLeaderboardEntries(var1, var2, var3):
	print(prefix + "Downloaded leaderboard entries")

func findLeaderboard(var1):
	print(prefix + "Found leaderboard")

func getFriendPersonaName(var1):
	print(prefix + "Got friend persona name")
	return ""

func getLeaderboardEntryCount(var1):
	print(prefix + "Got leaderboard entry count")
	return 0

func getSteamID():
	print(prefix + "Got steam ID")
	return 0

func run_callbacks():
	print(prefix + "Ran callbacks")

func setAchievement(var1):
	print(prefix + "Set achievement")

func setLeaderboardDetailsMax(var1):
	print(prefix + "Set leaderboard details max")
	return 0

func steamInit(var1):
	print(prefix + "Initialized Steam")
	return {}

func storeStats():
	print(prefix + "Stored stats")

func uploadLeaderboardScore(var1, var2, var3, var4):
	print(prefix + "Uploaded leaderboard score")
