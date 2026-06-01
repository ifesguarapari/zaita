extends Area2D
class_name NarrativeCollectible

signal collected(collectible: NarrativeCollectible)

const COLLECTIBLE_TEXTURE := preload("res://assets/images/zaita-collectibles.png")
# The source PNG is a transparent catalog of childhood objects.
const COLLECTIBLE_REGIONS := [
	Rect2(82, 770, 193, 382), # Flower
	Rect2(23, 35, 376, 436), # Doll
	Rect2(1084, 831, 408, 281), # Crayons
	Rect2(1268, 480, 393, 322), # Bottle caps
	Rect2(689, 410, 492, 394), # Tin with marbles
	Rect2(688, 1492, 341, 319), # Matchbox-like domino
	Rect2(810, 1207, 391, 254), # Used sticks
	Rect2(2729, 424, 567, 408), # Notebook
]
const DISPLAY_SIZE := 42.0

@export var object_name := "Lembrança"
@export_multiline var narrative_message := "Uma lembrança permaneceu no caminho."
@export_range(0, 7, 1) var icon_index := 0

@onready var sprite: Sprite2D = $Sprite2D

var _elapsed_time := 0.0
var _was_collected := false
var _base_scale := 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_apply_icon()


func _process(delta: float) -> void:
	_elapsed_time += delta
	var pulse := 1.0 + sin(_elapsed_time * 3.0) * 0.08
	sprite.scale = Vector2.ONE * _base_scale * pulse


func configure(new_name: String, new_message: String, new_icon_index: int) -> void:
	object_name = new_name
	narrative_message = new_message
	icon_index = new_icon_index % COLLECTIBLE_REGIONS.size()
	if is_node_ready():
		_apply_icon()


func _apply_icon() -> void:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = COLLECTIBLE_TEXTURE
	atlas_texture.region = COLLECTIBLE_REGIONS[icon_index]
	sprite.texture = atlas_texture
	var largest_side: float = maxf(atlas_texture.region.size.x, atlas_texture.region.size.y)
	_base_scale = DISPLAY_SIZE / largest_side


func _on_body_entered(body: Node2D) -> void:
	if _was_collected or not body.is_in_group("player"):
		return
	_was_collected = true
	set_deferred("monitoring", false)
	collected.emit(self)
