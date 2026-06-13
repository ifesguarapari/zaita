extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	main_scene._on_start_requested()
	await process_frame

	var generator: MazeGenerator = main_scene.get_node("MazeGenerator")
	var player: ZaitaPlayer = main_scene.get_node("Player")
	var collectibles: Node2D = main_scene.get_node("Collectibles")
	var represented_groups := {}
	for sprite in generator.decorations.get_children() + generator.overlays.get_children():
		represented_groups[sprite.get_meta("tileset_group")] = true

	assert(generator.map_width == 50)
	assert(generator.map_height == 50)
	assert(generator.tile_size == 80)
	assert(generator.road_width >= 3)
	assert(generator._road_cells.size() > 0)
	assert(generator._plaza_cells.size() > 0)
	assert(generator._road_edges.size() >= generator._road_nodes.size() - 1)
	assert(generator.road_visuals.get_child_count() == 1)
	assert(generator.road_visuals.z_index >= 0)
	var road_floor: Sprite2D = generator.road_visuals.get_child(0)
	var expected_road_texture_sample_size: float = mini(
		generator._road_texture.get_width(),
		generator._road_texture.get_height()
	) * generator.ROAD_TEXTURE_REGION_RATIO
	var source_region: Rect2i = road_floor.get_meta("source_texture_region")
	assert(road_floor.get_meta("tileset_group") == "clay")
	assert(road_floor.get_meta("texture_path") == generator.ROAD_TEXTURE_PATH)
	assert(road_floor.get_meta("covers_map"))
	assert(road_floor.texture == generator._road_texture)
	assert(road_floor.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	assert(not road_floor.region_enabled)
	assert(source_region.size == Vector2i.ONE * roundi(expected_road_texture_sample_size))
	assert(is_equal_approx(generator._road_texture.get_width() * road_floor.scale.x, generator.map_width * generator.tile_size))
	assert(is_equal_approx(generator._road_texture.get_height() * road_floor.scale.y, generator.map_height * generator.tile_size))
	assert(road_floor.material is ShaderMaterial)
	assert((road_floor.material as ShaderMaterial).shader == generator.ROAD_TEXTURE_SHADER)
	assert(is_equal_approx(
		(road_floor.material as ShaderMaterial).get_shader_parameter("texture_repeat"),
		generator.ROAD_TEXTURE_REPEAT
	))
	assert(generator.streets.get_cell_source_id(generator._road_cells[0]) == generator.SOURCE_ID)
	assert(generator.streets.get_cell_atlas_coords(generator._road_cells[0]) == generator._atlas_cells_by_group["floors"][0])
	assert(generator.streets.get_cell_atlas_coords(generator._plaza_cells[0]) in generator._atlas_cells_by_group["floors"])
	assert(generator.streets.get_cell_source_id(generator._blocked_cells[0]) == -1)
	assert(generator._runtime_tile_set.get_occlusion_layers_count() == 0)
	assert(_get_runtime_world_bound_count(generator) == 4)
	assert(generator.world_bounds.has_node("EditorPlaceholder"))
	assert(collectibles.get_child_count() == generator.collectible_count)
	for collectible: NarrativeCollectible in collectibles.get_children():
		var cell := _global_position_to_cell(generator, collectible.global_position)
		assert(cell in generator._road_cells)

	for group_name in [
		"small_houses",
		"medium_houses",
		"roofs",
		"walls",
		"stairs",
		"urban_objects",
		"childhood_details",
		"shadows",
	]:
		assert(represented_groups.has(group_name))
	assert(not represented_groups.has("puddles"))
	assert(not represented_groups.has("lights"))
	assert(not main_scene.has_node("WorldAtmosphere"))
	var initial_instructions: String = main_scene.get_node("UI/StartPopup/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Instructions").text
	assert("WASD" not in initial_instructions)
	assert("setas" not in initial_instructions)
	Input.action_press("ui_right")
	assert(player._get_input_direction() == Vector2.ZERO)
	Input.action_release("ui_right")

	var map_rect := generator.get_global_pixel_rect()
	player.global_position = Vector2(map_rect.position.x + 16.0, map_rect.position.y + generator.tile_size * 2.5)
	var boundary_collision := player.move_and_collide(Vector2.LEFT * generator.tile_size * 2.0)
	assert(boundary_collision != null)
	assert(player.global_position.x >= map_rect.position.x)

	var player_light := player.get_node("PointLight2D") as PointLight2D
	assert(player_light != null)
	assert(player_light.color == Color.WHITE)
	assert(is_equal_approx(player_light.energy, 0.18))
	assert(is_equal_approx(player_light.texture_scale, 2.35))
	assert(not player_light.shadow_enabled)
	var foot_shadow := player.get_node("FootShadow") as Sprite2D
	assert(foot_shadow != null)
	assert(foot_shadow.z_index < player.sprite.z_index)
	assert(foot_shadow.position == Vector2(0.0, -0.8))
	assert(foot_shadow.scale == Vector2(0.13, 0.03))
	assert(foot_shadow.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	assert(player.camera.zoom == Vector2(0.92, 0.92))
	var focus_material := main_scene.get_node("WorldFilter/ColorFocusOverlay").material as ShaderMaterial
	assert(focus_material.get_shader_parameter("focus_ellipse") == Vector2(1.58, 0.78))
	assert(focus_material.get_shader_parameter("focus_drift") == Vector2(0.012, 0.006))
	assert(is_equal_approx(focus_material.get_shader_parameter("focus_pulse_min"), 1.0))
	assert(is_equal_approx(focus_material.get_shader_parameter("focus_pulse_max"), 2.0))
	assert(is_equal_approx(focus_material.get_shader_parameter("focus_pulse_speed"), 0.78))
	assert(focus_material.get_shader_parameter("foot_ellipse") == Vector2(0.066, 0.02))
	assert(focus_material.get_shader_parameter("foot_offset") == Vector2(0.0, -0.004))
	assert(focus_material.get_shader_parameter("foot_shadow_color") == Vector3(0.18, 0.17, 0.16))
	assert(is_equal_approx(focus_material.get_shader_parameter("foot_shadow_strength"), 0.0))
	assert(is_equal_approx(focus_material.get_shader_parameter("foot_shadow_core_strength"), 0.0))
	assert(is_equal_approx(focus_material.get_shader_parameter("color_radius"), 0.19))
	assert(is_equal_approx(focus_material.get_shader_parameter("fade_width"), 0.12))
	assert(is_equal_approx(focus_material.get_shader_parameter("distant_saturation"), 0.0))
	assert(is_equal_approx(focus_material.get_shader_parameter("distant_brightness"), 1.0))
	assert(is_equal_approx(focus_material.get_shader_parameter("distant_gray_floor"), 0.46))
	assert(is_equal_approx(focus_material.get_shader_parameter("vignette_strength"), 0.0))
	player.global_position = Vector2(generator.tile_size * 2.0, generator.map_height * generator.tile_size - generator.tile_size)
	player._physics_process(0.016)
	assert(player.z_index == player.ACTOR_Z_OFFSET)
	for animation_name in ["idle-south", "run-east", "run-north", "run-north-east", "run-south-east", "run-south"]:
		player._play_animation(animation_name)
		var frame_texture := player.sprite.sprite_frames.get_frame_texture(animation_name, 0)
		assert(is_equal_approx(frame_texture.get_height() * player.sprite.scale.y, player.PLAYER_DISPLAY_HEIGHT))
	player._movement_enabled = true
	player.velocity = Vector2.LEFT * player.speed
	player._update_visual_facing(0.016, Vector2.LEFT)
	player._update_animation()
	assert(player.sprite.animation == "run-east")
	assert(player.sprite.flip_h)

	player.velocity = Vector2(1.0, -1.0).normalized() * player.speed
	player._update_visual_facing(0.016, Vector2(1.0, -1.0).normalized())
	player._update_animation()
	assert(player.sprite.animation == "run-north-east")
	assert(not player.sprite.flip_h)

	player.velocity = Vector2(-1.0, -1.0).normalized() * player.speed
	player._update_visual_facing(0.016, Vector2(-1.0, -1.0).normalized())
	player._update_animation()
	assert(player.sprite.animation == "run-north-east")
	assert(player.sprite.flip_h)

	player.velocity = Vector2.ZERO
	for _index in range(40):
		player._update_visual_facing(0.016, Vector2.ZERO)
		player._update_animation()
	assert(player.sprite.animation == "idle-south")
	assert(not player.sprite.flip_h)

	var isolated_collectible := (load("res://scenes/Collectible.tscn") as PackedScene).instantiate() as NarrativeCollectible
	var test_player := CharacterBody2D.new()
	test_player.add_to_group("player")
	root.add_child(isolated_collectible)
	root.add_child(test_player)
	await process_frame
	assert(is_equal_approx((isolated_collectible.get_node("CollisionShape2D").shape as CircleShape2D).radius, 24.0))
	isolated_collectible._on_body_entered(test_player)
	await process_frame
	assert(not isolated_collectible.monitoring)

	main_scene._reset_game()
	await process_frame
	assert(_get_runtime_world_bound_count(generator) == 4)
	assert(generator.road_visuals.get_child_count() == 1)
	assert(collectibles.get_child_count() == generator.collectible_count)

	print("ZAITA_RUNTIME_SMOKE_TEST_OK")
	quit()


func _global_position_to_cell(generator: MazeGenerator, global_position: Vector2) -> Vector2i:
	var local_position := generator.to_local(global_position)
	return Vector2i(floori(local_position.x / generator.tile_size), floori(local_position.y / generator.tile_size))


func _get_runtime_world_bound_count(generator: MazeGenerator) -> int:
	var count := 0
	for child in generator.world_bounds.get_children():
		if child.has_meta("runtime_world_bound"):
			count += 1
	return count
