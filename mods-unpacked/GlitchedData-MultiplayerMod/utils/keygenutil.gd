extends Node

var crypto = Crypto.new()
var privateKey = CryptoKey.new()
var nottherightkey = CryptoKey.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	KeyGen()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func KeyGen():
	privateKey = crypto.generate_rsa(4096)
	nottherightkey = crypto.generate_rsa(4096)
	var data = "keygentest"
	var signature = crypto.sign(HashingContext.HASH_SHA256, data.sha256_buffer(), privateKey)
	var verify = crypto.verify(HashingContext.HASH_SHA256, data.sha256_buffer(), signature, privateKey)
	if verify:
		print("Key matches")
