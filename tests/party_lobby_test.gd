extends SceneTree

const PartySession := preload("res://addons/couch_party/core/party_session.gd")
const InputRouter := preload("res://addons/couch_party/input/device_input_router.gd")
const PartyLobby := preload("res://addons/couch_party/ui/party_lobby.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var party: RefCounted = PartySession.new()
	var router: RefCounted = InputRouter.new()
	var lobby: Control = PartyLobby.new()
	root.add_child(lobby)
	lobby.setup(party, router, {"title": "TEST PARTY"})
	_expect_equal(lobby.handle_event(_button(0, JOY_BUTTON_START)), "joined", "Start should join an unused controller", failures)
	lobby.handle_event(_button(0, JOY_BUTTON_START, false))
	_expect_equal(lobby.handle_event(_button(0, JOY_BUTTON_START)), "ready", "Start should ready its joined player", failures)
	lobby.handle_event(_button(0, JOY_BUTTON_START, false))
	_expect_equal(lobby.handle_event(_key(KEY_ENTER)), "joined", "Enter should join the keyboard", failures)
	lobby.handle_event(_key(KEY_ENTER, false))
	_expect_equal(lobby.handle_event(_key(KEY_ENTER)), "ready", "Enter should ready the keyboard", failures)
	lobby.handle_event(_key(KEY_ENTER, false))
	_expect_equal(lobby.handle_event(_button(0, JOY_BUTTON_START)), "start_requested", "a ready player should start a fully ready party", failures)
	lobby.handle_event(_button(0, JOY_BUTTON_START, false))
	_expect_equal(lobby.handle_event(_button(0, JOY_BUTTON_B)), "unready", "cancel should first unready a player", failures)
	lobby.handle_event(_button(0, JOY_BUTTON_B, false))
	_expect_equal(lobby.handle_event(_button(0, JOY_BUTTON_B)), "left", "cancel should then release an unready slot", failures)
	lobby.queue_free()
	if failures.is_empty():
		print("PASS: party lobby")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _button(device_id: int, button: JoyButton, pressed: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button
	event.pressed = pressed
	return event


func _key(keycode: Key, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	return event


func _expect_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
