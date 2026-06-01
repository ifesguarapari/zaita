extends ColorRect

@export var target_path: NodePath

@onready var target: Node2D = get_node(target_path)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)


func _process(_delta: float) -> void:
	if target == null or material == null:
		return
	var viewport_size := get_viewport_rect().size
	var screen_position := get_viewport().get_canvas_transform() * target.global_position
	material.set_shader_parameter("focus_position", screen_position / viewport_size)
	material.set_shader_parameter("aspect_ratio", viewport_size.x / viewport_size.y)


func _fit_to_viewport() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
