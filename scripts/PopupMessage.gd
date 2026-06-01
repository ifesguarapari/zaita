extends Control
class_name PopupMessage

signal closed

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var ok_button: Button = %OkButton


func _ready() -> void:
	ok_button.pressed.connect(_on_ok_button_pressed)


func show_message(title: String, message: String, button_text := "OK") -> void:
	title_label.text = title
	message_label.text = message
	ok_button.text = button_text
	show()
	ok_button.grab_focus()


func hide_message() -> void:
	hide()


func _on_ok_button_pressed() -> void:
	hide()
	closed.emit()
