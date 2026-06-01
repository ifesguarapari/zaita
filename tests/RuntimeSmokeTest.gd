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
	assert(generator.road_visuals.get_child_count() == generator._road_cells.size())
	assert(generator.road_visuals.z_index >= 0)
	var primary_floor_count := 0
	var varied_floor_count := 0
	for road_floor: Sprite2D in generator.road_visuals.get_children():
		assert(road_floor.get_meta("tileset_group") == "floors")
		assert(is_equal_approx(road_floor.region_rect.size.x * road_floor.scale.x, generator.tile_size - generator.ROAD_FLOOR_MARGIN))
		assert(is_equal_approx(road_floor.region_rect.size.y * road_floor.scale.y, generator.tile_size - generator.ROAD_FLOOR_MARGIN))
		assert(road_floor.material is ShaderMaterial)
		if road_floor.get_meta("source_floor_region") == generator.TILE_REGIONS["floors"][0]:
			primary_floor_count += 1
		if road_floor.get_meta("uses_floor_variation"):
			varied_floor_count += 1
	assert(primary_floor_count > 0)
	assert(varied_floor_count > 0)
	assert(generator.streets.get_cell_source_id(generator._road_cells[0]) == generator.SOURCE_ID)
	assert(generator.streets.get_cell_atlas_coords(generator._road_cells[0]) == generator._atlas_cells_by_group["floors"][0])
	assert(generator.streets.get_cell_atlas_coords(generator._plaza_cells[0]) in generator._atlas_cells_by_group["floors"])
	assert(generator.streets.get_cell_source_id(generator._blocked_cells[0]) == -1)
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

	assert(player.get_node("PointLight2D") is PointLight2D)
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
	assert(generator.road_visuals.get_child_count() == generator._road_cells.size())
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
