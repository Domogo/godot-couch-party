extends SceneTree


const DemoScene := preload("res://examples/demo.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var demo := DemoScene.instantiate()
	root.add_child(demo)
	for _frame: int in 6:
		await process_frame
	demo.seed_preview_roster()
	for _frame: int in 2:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Demo capture requires a display-backed Godot run")
		quit(2)
		return
	var output_path := ProjectSettings.globalize_path("res://media/couch_party_lobby.png")
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Could not save lobby preview: %s" % error_string(error))
		quit(2)
		return
	print("CAPTURE_READY path=%s size=%s" % [output_path, image.get_size()])
	demo.free()
	quit(0)
