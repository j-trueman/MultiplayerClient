extends Node

var crypto = Crypto.new()
var privateKey = CryptoKey.new()
var signatureData = "multiplayersignature"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func KeyGen():
	privateKey.load("user://privatekey.key")
	if privateKey.save_to_string() != "":
		return false
	privateKey = crypto.generate_rsa(4096)
	privateKey.save("user://privatekey.key")
	var signature = crypto.sign(HashingContext.HASH_SHA256, signatureData.sha256_buffer(), privateKey)
	privateKey = CryptoKey.new()
	return signature

func verifyUserSignature(signature, key):
	var signatureMatches = crypto.verify(HashingContext.HASH_SHA256, signatureData.sha256_buffer(), signature, key)
	if !signatureMatches:
		return false
	return true
