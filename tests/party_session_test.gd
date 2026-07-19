extends SceneTree

const PartySession := preload("res://addons/couch_party/core/party_session.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_test_six_devices_receive_stable_slots(failures)
	_test_disconnect_reconnect_and_leave_preserve_identity(failures)
	_test_humans_and_bots_form_a_ready_roster(failures)
	_test_configured_keyboard_layouts_can_claim_separate_slots(failures)
	if failures.is_empty():
		print("PASS: party session")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_six_devices_receive_stable_slots(failures: Array[String]) -> void:
	var party: RefCounted = PartySession.new()
	var devices: Array[int] = [PartySession.KEYBOARD_PRIMARY, 0, 1, 2, 3, 4]
	for index: int in devices.size():
		_expect_equal(
			party.join(devices[index]),
			index + 1,
			"device %d should receive player slot %d" % [devices[index], index + 1],
			failures,
		)
	_expect_equal(party.join(0), 2, "joining twice should preserve the slot", failures)
	_expect_equal(party.join(5), -1, "a seventh device should be rejected", failures)


func _test_disconnect_reconnect_and_leave_preserve_identity(failures: Array[String]) -> void:
	var party: RefCounted = PartySession.new()
	var original_player_id: int = party.join(7)
	_expect(party.disconnect_device(7), "an assigned device should disconnect", failures)
	_expect(not party.is_player_connected(original_player_id), "the slot should report disconnected", failures)
	_expect_equal(party.reconnect(7), original_player_id, "reconnect should restore the same slot", failures)
	_expect(party.is_player_connected(original_player_id), "the restored slot should report connected", failures)
	_expect(party.leave(7), "an assigned lobby device should leave", failures)
	_expect_equal(party.player_for_device(7), -1, "leaving should release the assignment", failures)
	_expect_equal(party.join(8), original_player_id, "the released slot should be reusable", failures)


func _test_humans_and_bots_form_a_ready_roster(failures: Array[String]) -> void:
	var party: RefCounted = PartySession.new()
	var human_id: int = party.join(PartySession.KEYBOARD_PRIMARY)
	var bot_id: int = party.add_bot(PartySession.BOT_EASY)
	_expect_equal(bot_id, 2, "a bot should occupy an ordinary player slot", failures)
	_expect(not party.can_start(), "an unready human should block match start", failures)
	_expect(party.set_ready(PartySession.KEYBOARD_PRIMARY, true), "a human device should become ready", failures)
	_expect(party.can_start(), "one ready human and one bot should start", failures)
	_expect(party.set_bot_difficulty(bot_id, PartySession.BOT_HARD), "bot difficulty should be editable", failures)
	var roster: Dictionary = party.snapshot()
	_expect_equal(roster[human_id]["control_kind"], "human", "the human slot should retain its kind", failures)
	_expect_equal(roster[bot_id]["control_kind"], "bot", "the bot slot should expose its kind", failures)
	_expect(not roster[bot_id].has("device_id"), "bots should not receive fake input devices", failures)
	_expect_equal(roster[bot_id]["bot_difficulty"], PartySession.BOT_HARD, "the bot should expose its difficulty", failures)
	_expect(party.remove_bot(bot_id), "a bot should be removable", failures)
	_expect(not party.can_start(), "one participant should not start", failures)


func _test_configured_keyboard_layouts_can_claim_separate_slots(failures: Array[String]) -> void:
	var party: RefCounted = PartySession.new({"keyboard_device_ids": [-1, -2]})
	_expect_equal(party.join(-1), 1, "the primary keyboard should join", failures)
	_expect_equal(party.join(-2), 2, "a configured secondary keyboard layout should join", failures)
	_expect_equal(party.join(-3), -1, "an unconfigured synthetic keyboard should be rejected", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
