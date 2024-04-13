extends Node

var crypto = Crypto.new()
var privateKey = CryptoKey.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func KeyGen() -> PackedByteArray:
	privateKey = crypto.generate_rsa(4096)
	privateKey.save("user://privatekey.pub")
	var data = "multiplayersignature"
	var signature = crypto.sign(HashingContext.HASH_SHA256, data.sha256_buffer(), privateKey)
	return signature
