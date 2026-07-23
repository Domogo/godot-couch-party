extends SceneTree

const PartySession := preload("res://addons/couch_party/core/party_session.gd")
const PartyLobbyView := preload("res://addons/couch_party/ui/party_lobby_view.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var party: RefCounted = PartySession.new()
	party.join(PartySession.KEYBOARD_PRIMARY)
	party.set_ready(PartySession.KEYBOARD_PRIMARY, true)
	party.add_bot(PartySession.BOT_HARD)
	var view: Control = PartyLobbyView.new()
	root.add_child(view)
	view.setup({"title": "TEST PARTY", "max_players": 6})
	view.render(party.snapshot())
	var slot_texts: Array[String] = view.slot_texts()
	_expect(slot_texts.size() == 6, "the lobby should expose all six slots", failures)
	_expect("KEYBOARD" in slot_texts[0] and "READY" in slot_texts[0], "the human slot should show device and readiness", failures)
	_expect("CPU" in slot_texts[1] and "HARD" in slot_texts[1], "the bot slot should show kind and difficulty", failures)
	_expect("EMPTY" in slot_texts[2], "unused slots should remain visible", failures)
	var start_button := _button_with_text(view, "START MATCH")
	_expect(start_button != null and not start_button.disabled, "a ready roster should enable Start", failures)
	party.set_ready(PartySession.KEYBOARD_PRIMARY, false)
	view.render(party.snapshot())
	_expect(start_button.disabled, "an unready human should disable Start", failures)
	view.render_lobby({
		"roster": party.snapshot(),
		"can_start": false,
		"can_add_bot": true,
		"can_remove_bot": true,
		"max_players": 8,
	})
	_expect_equal(
		view.slot_texts().size(),
		8,
		"the default view should follow the session capacity from lobby state",
		failures,
	)
	var requested_difficulties: Array[String] = []
	view.add_bot_requested.connect(func(difficulty: String) -> void:
		requested_difficulties.append(difficulty)
	)
	for node: Node in view.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text.begins_with("+"):
			button.pressed.emit()
	_expect(
		requested_difficulties == ["easy", "medium", "hard"],
		"the lobby buttons should request every published bot difficulty",
		failures,
	)
	view.queue_free()
	if failures.is_empty():
		print("PASS: party lobby view")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _button_with_text(view: Control, text: String) -> Button:
	for node: Node in view.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == text:
			return button
	return null


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(
	actual: Variant,
	expected: Variant,
	message: String,
	failures: Array[String],
) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
