extends Node

@export var textField : Label3D
@export var placeholderText : String
@export var isFocused : bool = false
@export var viewingCRT : bool

var alphabet =  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Called when the node enters the scene tree for the first time.
func _ready():
	textField.text = placeholderText
	textField.set_modulate(Color(0,1,0,0.2))
	viewingCRT = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func resetInput():
	textField.text = placeholderText
	textField.set_modulate(Color(0,1,0,0.2))
	viewingCRT = false
	isFocused = false

func clearInput():
	isFocused = true
	textField.text = ""
	textField.set_modulate(Color(0,1,0,1))

func SetViewing(option):
	if option == true:
		viewingCRT = true
	else:
		viewingCRT = false

func _input(ev):
	if !isFocused && viewingCRT and ev is InputEventKey:
		var keycode = OS.get_keycode_string(ev.keycode)
		if keycode in alphabet:
			clearInput()
	if isFocused && viewingCRT:
		if ev is InputEventKey and not ev.echo and ev.pressed:
			var keycode = OS.get_keycode_string(ev.keycode)
			if keycode in alphabet and len(textField.text) < 8:
				textField.text += OS.get_keycode_string(ev.keycode)
			elif keycode == "Backspace" and textField.text != "":
				textField.text = textField.text.erase(len(textField.text) - 1, 1)
		if ev is InputEventKey and ev.pressed and placeholderText not in textField.text:
			var keycode = OS.get_keycode_string(ev.keycode)
			if keycode == "Backspace" and textField.text != "":
				textField.text = textField.text.erase(len(textField.text) - 1, 1)
	
