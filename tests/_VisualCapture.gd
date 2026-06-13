extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await process_frame
	main_scene.get_node("UI/StartPopup")._on_start_button_pressed()
	for _index in range(10):
		await process_frame

	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("/tmp/zaita-clay-floor.png")
	assert(error == OK)
	print("ZAITA_VISUAL_CAPTURE_OK /tmp/zaita-clay-floor.png")
	quit()
