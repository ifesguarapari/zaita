extends Control
class_name EightDirectionTouchJoystick

var radius := 62.0
var knob_radius := 22.0
var center := Vector2.ZERO
var knob := Vector2.ZERO
var dragging := false
var active_pointer := -1
var movement_vector := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)
	center = size * 0.5
	knob = center


func clear_input() -> void:
	dragging = false
	active_pointer = -1
	movement_vector = Vector2.ZERO
	knob = center
	queue_redraw()


func _fit_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(22, max(20.0, viewport_size.y - 172.0))
	size = Vector2(150, 150)
	center = size * 0.5
	if not dragging:
		knob = center
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _inside(event.position):
			dragging = true
			active_pointer = event.index
			_update_knob(event.position)
		elif active_pointer == event.index:
			clear_input()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and dragging and event.index == active_pointer:
		_update_knob(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _inside(event.position):
			dragging = true
			active_pointer = -2
			_update_knob(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and active_pointer == -2:
			clear_input()
	elif event is InputEventMouseMotion and dragging and active_pointer == -2:
		_update_knob(event.position)


func _draw() -> void:
	center = size * 0.5
	var base_color := Color(0.10, 0.07, 0.08, 0.58)
	var ring_color := Color(0.91, 0.72, 0.57, 0.62)
	var mark_color := Color(0.91, 0.72, 0.57, 0.48)
	draw_circle(center, radius, base_color)
	draw_arc(center, radius, 0, TAU, 64, ring_color, 2.0, true)

	for index in range(8):
		var direction := Vector2.from_angle(index * TAU / 8.0)
		draw_line(center + direction * 38.0, center + direction * 53.0, mark_color, 3.0, true)

	draw_circle(knob, knob_radius, Color(0.94, 0.82, 0.69, 0.88))
	draw_circle(knob, knob_radius * 0.42, Color(0.27, 0.15, 0.15, 0.58))


func _update_knob(local_position: Vector2) -> void:
	var delta := local_position - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	knob = center + delta
	movement_vector = _snap_to_eight_directions(delta / radius)
	queue_redraw()


func _snap_to_eight_directions(input_vector: Vector2) -> Vector2:
	if input_vector.length() < 0.08:
		return Vector2.ZERO
	var snapped_angle := roundf(input_vector.angle() / (PI / 4.0)) * (PI / 4.0)
	return Vector2.from_angle(snapped_angle) * minf(input_vector.length(), 1.0)


func _inside(local_position: Vector2) -> bool:
	return local_position.distance_to(center) <= radius + 20.0
