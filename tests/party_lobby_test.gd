extends SceneTree

const PartySession := preload("res://addons/couch_party/core/party_session.gd")
const InputRouter := preload("res://addons/couch_party/input/device_input_router.gd")
const PartyLobby := preload("res://addons/couch_party/ui/party_lobby.gd")


class RecordingLobbyView:
	extends Control

	signal add_bot_requested(difficulty: String)
	signal remove_bot_requested
	signal start_requested

	var setup_title: String = ""
	var rendered_states: Array[Dictionary] = []

	func setup(options: Dictionary = {}) -> void:
		setup_title = String(options.get("title", ""))

	func render_lobby(state: Dictionary) -> void:
		rendered_states.append(state.duplicate(true))


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_controller_confirm_activates_focused_button(failures)
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
	_test_custom_view_receives_lobby_capabilities(failures)
	if failures.is_empty():
		print("PASS: party lobby")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_controller_confirm_activates_focused_button(failures: Array[String]) -> void:
	var party: RefCounted = PartySession.new()
	var router: RefCounted = InputRouter.new()
	var lobby: Control = PartyLobby.new()
	root.add_child(lobby)
	_expect(lobby.setup(party, router), "the default lobby should configure", failures)
	var easy_bot_button := _button_with_text(lobby, "+ EASY BOT")
	_expect(easy_bot_button != null, "the default lobby should expose its first focused action", failures)
	if easy_bot_button != null:
		easy_bot_button.grab_focus()
		lobby.call("_input", _button(0, JOY_BUTTON_A))
		_expect(
			party.player_for_device(0) == 1
			and bool(party.snapshot()[1]["ready"])
			and party.bot_player_ids().is_empty(),
			"the first controller A press should join and ready its physical device",
			failures,
		)
		lobby.call("_input", _button(0, JOY_BUTTON_A, false))
		lobby.call("_input", _button(0, JOY_BUTTON_A))
		_expect_equal(
			party.bot_player_ids().size(),
			1,
			"controller A should activate the focused lobby button after joining",
			failures,
		)
	lobby.queue_free()


func _test_custom_view_receives_lobby_capabilities(failures: Array[String]) -> void:
	var party: RefCounted = PartySession.new()
	var router: RefCounted = InputRouter.new()
	var view := RecordingLobbyView.new()
	var lobby: Control = PartyLobby.new()
	root.add_child(lobby)
	lobby.setup(party, router, {
		"title": "CUSTOM PARTY",
		"view": view,
	})
	_expect(view.get_parent() == lobby, "a supplied custom view should be installed", failures)
	_expect_equal(view.setup_title, "CUSTOM PARTY", "view setup should receive public options", failures)
	_expect_equal(view.rendered_states.size(), 1, "the custom view should receive initial state", failures)
	_expect(
		not bool(view.rendered_states[-1]["can_start"]),
		"the initial custom view state should disable start",
		failures,
	)
	lobby.handle_event(_key(KEY_ENTER))
	lobby.handle_event(_key(KEY_ENTER, false))
	lobby.handle_event(_key(KEY_ENTER))
	lobby.handle_event(_key(KEY_ENTER, false))
	view.add_bot_requested.emit(PartySession.BOT_HARD)
	var ready_state: Dictionary = view.rendered_states[-1]
	_expect(bool(ready_state["can_start"]), "the custom view should receive start capability", failures)
	_expect_equal(
		(ready_state["roster"] as Dictionary).size(),
		2,
		"the custom view state should contain the current roster",
		failures,
	)
	var requested_starts: Array[Dictionary] = []
	lobby.start_requested.connect(func(roster: Dictionary) -> void:
		requested_starts.append(roster)
	)
	view.start_requested.emit()
	_expect_equal(requested_starts.size(), 1, "custom view controls should reach the lobby", failures)
	lobby.queue_free()


func _button_with_text(parent: Node, text: String) -> Button:
	for node: Node in parent.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == text:
			return button
	return null


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


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
