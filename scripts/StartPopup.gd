extends Control
class_name StartPopup

signal start_requested

@onready var start_button: Button = %StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)


func open() -> void:
	show()
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	hide()
	start_requested.emit()
