extends SceneTree

const InputRouter := preload("res://addons/couch_party/input/device_input_router.gd")
const InputProfile := preload("res://addons/couch_party/input/input_profile.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_controller_frames_are_device_specific_and_buffer_edges(failures)
	_test_keyboard_uses_the_same_semantic_frame(failures)
	_test_profile_can_remap_controller_and_add_keyboard_layout(failures)
	if failures.is_empty():
		print("PASS: device input router")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_controller_frames_are_device_specific_and_buffer_edges(failures: Array[String]) -> void:
	var router: RefCounted = InputRouter.new()
	router.ingest(_motion(3, JOY_AXIS_LEFT_X, 0.8))
	router.ingest(_motion(3, JOY_AXIS_LEFT_Y, -0.4))
	router.ingest(_button(3, JOY_BUTTON_X, true))
	router.ingest(_button(3, JOY_BUTTON_X, false))
	var player_frame: Dictionary = router.frame_for_device(3)
	var other_frame: Dictionary = router.frame_for_device(4)
	_expect((player_frame["move"] as Vector2).distance_to(Vector2(0.8, -0.4)) < 0.001, "left stick should be preserved", failures)
	_expect(bool(player_frame["primary_pressed"]), "a short west-button tap should reach one frame", failures)
	_expect(not bool(player_frame["primary_held"]), "released west button should not remain held", failures)
	_expect_equal(other_frame["move"], Vector2.ZERO, "another controller should remain isolated", failures)
	_expect(not bool(router.frame_for_device(3)["primary_pressed"]), "the buffered edge should be consumed once", failures)


func _test_keyboard_uses_the_same_semantic_frame(failures: Array[String]) -> void:
	var router: RefCounted = InputRouter.new()
	router.ingest(_key(KEY_D, true))
	router.ingest(_key(KEY_E, true))
	router.ingest(_key(KEY_E, false))
	router.ingest(_key(KEY_SPACE, true))
	var frame: Dictionary = router.frame_for_device(InputRouter.KEYBOARD_PRIMARY)
	_expect_equal(frame["move"], Vector2.RIGHT, "D should produce the shared movement field", failures)
	_expect(bool(frame["primary_pressed"]), "E should produce the shared primary edge", failures)
	_expect(bool(frame["secondary_held"]), "Space should produce the shared secondary hold", failures)
	router.clear_device(InputRouter.KEYBOARD_PRIMARY)
	_expect_equal(router.frame_for_device(InputRouter.KEYBOARD_PRIMARY)["move"], Vector2.ZERO, "clearing should release keyboard state", failures)


func _test_profile_can_remap_controller_and_add_keyboard_layout(failures: Array[String]) -> void:
	var profile: RefCounted = InputProfile.new()
	profile.set_controller_bindings({
		"primary": JOY_BUTTON_A,
		"secondary": JOY_BUTTON_X,
		"tertiary": JOY_BUTTON_Y,
		"menu": JOY_BUTTON_START,
		"cancel": JOY_BUTTON_B,
	})
	profile.add_keyboard_layout(-2, {
		"move_left": KEY_LEFT,
		"move_right": KEY_RIGHT,
		"move_up": KEY_UP,
		"move_down": KEY_DOWN,
		"primary": KEY_PERIOD,
		"secondary": KEY_SLASH,
		"tertiary": KEY_COMMA,
		"menu": KEY_ENTER,
		"cancel": KEY_BACKSPACE,
	})
	var router: RefCounted = InputRouter.new({"profile": profile})
	router.ingest(_button(2, JOY_BUTTON_A, true))
	router.ingest(_key(KEY_RIGHT, true))
	router.ingest(_key(KEY_PERIOD, true))
	_expect(bool(router.frame_for_device(2)["primary_pressed"]), "the controller primary button should be remappable", failures)
	var keyboard_frame: Dictionary = router.frame_for_device(-2)
	_expect_equal(keyboard_frame["move"], Vector2.RIGHT, "an additional keyboard layout should route independently", failures)
	_expect(bool(keyboard_frame["primary_pressed"]), "the additional keyboard primary should use its own binding", failures)


func _motion(device_id: int, axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = device_id
	event.axis = axis
	event.axis_value = value
	return event


func _button(device_id: int, button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button
	event.pressed = pressed
	return event


func _key(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	return event


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
