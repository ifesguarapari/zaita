extends CharacterBody2D
class_name ZaitaPlayer

const ANIMATION_SHEETS := [
	{
		"name": "idle-south",
		"texture": "res://assets/sprites/zaita-idle-south.png",
		"json": "res://assets/sprites/zaita-idle-south.json",
	},
	{
		"name": "run-east",
		"texture": "res://assets/sprites/zaita-running-east.png",
		"json": "res://assets/sprites/zaita-running-east.json",
	},
	{
		"name": "run-north",
		"texture": "res://assets/sprites/zaita-running-north.png",
		"json": "res://assets/sprites/zaita-running-north.json",
	},
	{
		"name": "run-north-east",
		"texture": "res://assets/sprites/zaita-running-north-east.png",
		"json": "res://assets/sprites/zaita-running-north-east.json",
	},
	{
		"name": "run-south-east",
		"texture": "res://assets/sprites/zaita-running-south-east.png",
		"json": "res://assets/sprites/zaita-running-south-east.json",
	},
	{
		"name": "run-south",
		"texture": "res://assets/sprites/zaita-running-south.png",
		"json": "res://assets/sprites/zaita-running-south.json",
	},
]
const ACTOR_Z_OFFSET := 1000
const STOP_SPEED := 3.0
const PLAYER_DISPLAY_HEIGHT := 54.8

@export_category("Movement")
@export var speed: float = 150.0
@export var acceleration: float = 720.0
@export var friction: float = 560.0

@export_category("Visual Transition")
@export var front_return_delay: float = 0.08
@export var front_return_duration: float = 0.42

@export_category("Camera")
@export var camera_look_ahead := Vector2(42.0, 26.0)
@export var camera_response: float = 3.4
@export var camera_bob_amount: float = 1.6

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var touch_joystick: EightDirectionTouchJoystick = (
	get_tree().get_first_node_in_group("touch_navigation") as EightDirectionTouchJoystick
)

var _movement_enabled := false
var _visual_facing := Vector2.DOWN
var _front_return_elapsed := 0.0
var _front_return_wait := 0.0
var _front_return_start_angle := Vector2.DOWN.angle()
var _returning_front := false
var _camera_time := 0.0
var _animation_source_heights := {}


func _ready() -> void:
	_build_sprite_frames_from_json()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = ACTOR_Z_OFFSET
	queue_redraw()
	_update_animation()


func _physics_process(delta: float) -> void:
	var input_direction := _get_input_direction() if _movement_enabled else Vector2.ZERO
	var target_velocity := input_direction * speed
	var change_rate := acceleration if input_direction != Vector2.ZERO else friction
	velocity = velocity.move_toward(target_velocity, change_rate * delta)

	if _movement_enabled:
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_update_visual_facing(delta, input_direction)
	_update_camera(delta)
	_update_animation()


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		_snap_idle_front()
		if touch_joystick != null:
			touch_joystick.clear_input()


func configure_camera_bounds(bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.limit_smoothed = true
	camera.reset_smoothing()


func _get_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	if touch_joystick != null and touch_joystick.movement_vector.length() > 0.05:
		direction = touch_joystick.movement_vector
	return direction.normalized()


func _update_visual_facing(delta: float, input_direction: Vector2) -> void:
	if input_direction.length_squared() > 0.01:
		_visual_facing = input_direction.normalized()
		_front_return_wait = 0.0
		_front_return_elapsed = 0.0
		_returning_front = false
		return

	if not _movement_enabled:
		_snap_idle_front()
		return

	_front_return_wait += delta
	if _front_return_wait < front_return_delay:
		return

	if not _returning_front:
		if _visual_facing.dot(Vector2.DOWN) > 0.999:
			return
		_returning_front = true
		_front_return_elapsed = 0.0
		_front_return_start_angle = _visual_facing.angle()

	_front_return_elapsed += delta
	var progress := clampf(_front_return_elapsed / front_return_duration, 0.0, 1.0)
	var eased_progress := smoothstep(0.0, 1.0, progress)
	var current_angle := lerp_angle(_front_return_start_angle, Vector2.DOWN.angle(), eased_progress)
	_visual_facing = Vector2.from_angle(current_angle)

	if progress >= 1.0:
		_snap_idle_front()


func _update_animation() -> void:
	var visually_moving := (
		_movement_enabled
		and (
			velocity.length() > STOP_SPEED
			or _returning_front
			or _front_return_wait > 0.0 and _visual_facing.dot(Vector2.DOWN) < 0.999
		)
	)

	if not visually_moving:
		sprite.flip_h = false
		_play_animation(&"idle-south")
		return

	var direction_name := _get_eight_direction_name(_visual_facing)
	var source_direction := _get_source_direction(direction_name)
	var animation_name := StringName("run-%s" % source_direction)
	sprite.flip_h = _visual_facing.x < -0.05
	_play_animation(animation_name)


func _play_animation(animation_name: StringName) -> void:
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)
	var source_height: float = _animation_source_heights.get(String(animation_name), PLAYER_DISPLAY_HEIGHT)
	sprite.scale = Vector2.ONE * (PLAYER_DISPLAY_HEIGHT / source_height)


func _update_camera(delta: float) -> void:
	_camera_time += delta
	var motion_ratio := clampf(velocity.length() / speed, 0.0, 1.0)
	var movement_direction := velocity.normalized() if motion_ratio > 0.01 else Vector2.ZERO
	var desired_offset := Vector2(
		movement_direction.x * camera_look_ahead.x,
		movement_direction.y * camera_look_ahead.y
	)
	var bob := Vector2(0.0, sin(_camera_time * 8.0) * camera_bob_amount * motion_ratio)
	var blend := 1.0 - exp(-camera_response * delta)
	camera.offset = camera.offset.lerp(desired_offset + bob, blend)


func _snap_idle_front() -> void:
	_visual_facing = Vector2.DOWN
	_front_return_wait = 0.0
	_front_return_elapsed = 0.0
	_returning_front = false


func _get_eight_direction_name(direction: Vector2) -> String:
	var octant := wrapi(roundi(direction.angle() / (PI / 4.0)), 0, 8)
	return [
		"east",
		"south-east",
		"south",
		"south-west",
		"west",
		"north-west",
		"north",
		"north-east",
	][octant]


func _get_source_direction(direction_name: String) -> String:
	match direction_name:
		"south":
			return "south"
		"south-east", "south-west":
			return "south-east"
		"east", "west":
			return "east"
		"north-east", "north-west":
			return "north-east"
		_:
			return "north"


func _build_sprite_frames_from_json() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for sheet: Dictionary in ANIMATION_SHEETS:
		_add_json_animation(frames, sheet["name"], sheet["texture"], sheet["json"])

	sprite.sprite_frames = frames


func _add_json_animation(
	frames: SpriteFrames,
	animation_name: String,
	texture_path: String,
	json_path: String
) -> void:
	var texture := load(texture_path) as Texture2D
	var parsed_data = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not parsed_data is Dictionary or not parsed_data.has("frames"):
		push_error("Could not parse animation metadata: %s" % json_path)
		return

	var frame_data: Dictionary = parsed_data["frames"]
	var frame_names := frame_data.keys()
	frame_names.sort()
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)

	var default_duration := 50.0
	var source_height := 1.0
	for frame_name: String in frame_names:
		var metadata: Dictionary = frame_data[frame_name]
		var region_data: Dictionary = metadata["frame"]
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(
			region_data["x"],
			region_data["y"],
			region_data["w"],
			region_data["h"]
		)
		frames.add_frame(animation_name, atlas_texture)
		default_duration = metadata.get("duration", default_duration)
		source_height = maxf(source_height, region_data["h"])

	frames.set_animation_speed(animation_name, 1000.0 / default_duration)
	_animation_source_heights[animation_name] = source_height


func _draw() -> void:
	_draw_soft_ellipse(Vector2(-19, -7), Vector2(38, 12), Color(1.0, 0.69, 0.25, 0.08))
	_draw_soft_ellipse(Vector2(-14, -5), Vector2(28, 9), Color(1.0, 0.76, 0.34, 0.12))
	_draw_soft_ellipse(Vector2(-9, -3), Vector2(18, 6), Color(1.0, 0.84, 0.48, 0.16))


func _draw_soft_ellipse(top_left: Vector2, ellipse_size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(
			top_left
			+ ellipse_size * 0.5
			+ Vector2(cos(angle) * ellipse_size.x * 0.5, sin(angle) * ellipse_size.y * 0.5)
		)
	draw_colored_polygon(points, color)
