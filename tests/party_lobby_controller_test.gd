extends SceneTree

const PartySession := preload("res://addons/couch_party/core/party_session.gd")
const InputRouter := preload("res://addons/couch_party/input/device_input_router.gd")
const PartyLobbyController := preload(
	"res://addons/couch_party/ui/party_lobby_controller.gd"
)


class AutoReadyPolicy:
	extends RefCounted

	func resolve_intent(intent: String, device_id: int, party: RefCounted) -> String:
		if intent != "menu":
			return "ignored"
		var player_id: int = party.player_for_device(device_id)
		if player_id < 0:
			player_id = party.join(device_id)
		if player_id < 0:
			return "full"
		party.set_ready(device_id, true)
		return "ready"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var party: RefCounted = PartySession.new()
	var router: RefCounted = InputRouter.new()
	var controller: RefCounted = PartyLobbyController.new()
	var observed_states: Array[Dictionary] = []
	controller.state_changed.connect(func(state: Dictionary) -> void:
		observed_states.append(state.duplicate(true))
	)
	_expect(controller.setup(party, router), "the controller should accept a party and router", failures)
	var initial_state: Dictionary = controller.lobby_state()
	_expect_equal(initial_state["max_players"], 6, "the state should expose party capacity", failures)
	_expect(not bool(initial_state["can_start"]), "an empty party should not start", failures)
	_expect(not bool(initial_state["can_remove_bot"]), "an empty party should not remove a bot", failures)

	_expect_equal(
		controller.handle_event(_button(0, JOY_BUTTON_START)),
		"joined",
		"Start should join through the headless controller",
		failures,
	)
	controller.handle_event(_button(0, JOY_BUTTON_START, false))
	controller.handle_event(_button(0, JOY_BUTTON_START))
	controller.handle_event(_button(0, JOY_BUTTON_START, false))
	controller.add_bot(PartySession.BOT_HARD)
	var ready_state: Dictionary = controller.lobby_state()
	_expect(bool(ready_state["can_start"]), "a ready human and bot should enable start", failures)
	_expect(bool(ready_state["can_remove_bot"]), "a bot should enable removal", failures)
	_expect(observed_states.size() >= 3, "observable state should follow roster changes", failures)
	_expect_equal(
		(observed_states[-1]["roster"] as Dictionary).size(),
		2,
		"state updates should contain the current roster",
		failures,
	)
	_test_custom_policy_can_change_join_behavior(failures)

	if failures.is_empty():
		print("PASS: party lobby controller")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_custom_policy_can_change_join_behavior(failures: Array[String]) -> void:
	var party: RefCounted = PartySession.new()
	var router: RefCounted = InputRouter.new()
	var controller: RefCounted = PartyLobbyController.new()
	_expect(
		controller.setup(party, router, {"policy": AutoReadyPolicy.new()}),
		"the controller should accept a lobby policy adapter",
		failures,
	)
	controller.add_bot(PartySession.BOT_MEDIUM)
	_expect_equal(
		controller.handle_event(_button(2, JOY_BUTTON_START)),
		"ready",
		"a custom policy should replace the default join-only behavior",
		failures,
	)
	_expect(
		bool(controller.lobby_state()["can_start"]),
		"custom policy mutations should refresh observable capabilities",
		failures,
	)


func _button(device_id: int, button: JoyButton, pressed: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button
	event.pressed = pressed
	return event


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
