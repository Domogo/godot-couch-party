class_name CouchPartyLobbyController
extends RefCounted


signal state_changed(state: Dictionary)
signal start_requested(roster: Dictionary)
signal action_resolved(action: String, device_id: int)

var _party: RefCounted
var _input_router: RefCounted
var _configured: bool = false
var _min_players: int = 2
var _require_human: bool = true
var _policy: RefCounted


func setup(
	party: RefCounted,
	input_router: RefCounted,
	options: Dictionary = {},
) -> bool:
	_configured = false
	_policy = null
	if party == null or input_router == null:
		return false
	_party = party
	_input_router = input_router
	_min_players = maxi(1, int(options.get("min_players", 2)))
	_require_human = bool(options.get("require_human", true))
	var configured_policy: Variant = options.get("policy")
	if configured_policy != null:
		if configured_policy is not RefCounted \
			or not (configured_policy as RefCounted).has_method("resolve_intent"):
			return false
		_policy = configured_policy as RefCounted
		if _policy.has_method("setup"):
			_policy.call("setup", options)
	_configured = true
	_refresh()
	return true


func handle_event(event: InputEvent) -> String:
	if not _configured:
		return "ignored"
	_input_router.ingest(event)
	var device_id: int = _input_router.device_for_event(event)
	if device_id == _input_router.NO_DEVICE or not _is_press_event(event):
		return "ignored"
	var frame: Dictionary = _input_router.frame_for_device(device_id)
	var action := "ignored"
	if bool(frame["menu_pressed"]):
		action = _resolve_intent("menu", device_id)
	elif bool(frame["cancel_pressed"]):
		action = _resolve_intent("cancel", device_id)
	elif bool(frame["secondary_pressed"]):
		action = "confirm_requested"
	if action != "ignored":
		if action == "left":
			_input_router.clear_device(device_id)
		if action == "start_requested":
			start_requested.emit(_party.snapshot())
		elif action not in ["full", "confirm_requested"]:
			_refresh()
		action_resolved.emit(action, device_id)
	return action


func device_connection_changed(device_id: int, connected: bool) -> String:
	if not _configured:
		return "ignored"
	var player_id: int = _party.player_for_device(device_id)
	if player_id < 0:
		return "available" if connected else "ignored"
	var action := "reconnected" if connected else "disconnected"
	if connected:
		_party.reconnect(device_id)
	else:
		_party.disconnect_device(device_id)
	_input_router.clear_device(device_id)
	_refresh()
	action_resolved.emit(action, device_id)
	return action


func add_bot(difficulty: String) -> int:
	if not _configured:
		return -1
	var player_id: int = _party.add_bot(difficulty)
	if player_id > 0:
		_refresh()
		action_resolved.emit("bot_added", _input_router.NO_DEVICE)
	return player_id


func remove_last_bot() -> bool:
	if not _configured:
		return false
	var bot_ids: Array[int] = _party.bot_player_ids()
	if bot_ids.is_empty() or not _party.remove_bot(bot_ids.back()):
		return false
	_refresh()
	action_resolved.emit("bot_removed", _input_router.NO_DEVICE)
	return true


func request_start() -> bool:
	if not _configured or not _can_start():
		return false
	start_requested.emit(_party.snapshot())
	action_resolved.emit("start_requested", _input_router.NO_DEVICE)
	return true


func lobby_state() -> Dictionary:
	if not _configured:
		return {
			"roster": {},
			"can_start": false,
			"can_add_bot": false,
			"can_remove_bot": false,
			"max_players": 0,
		}
	var roster: Dictionary = _party.snapshot()
	var max_players: int = (
		int(_party.max_players())
		if _party.has_method("max_players")
		else maxi(roster.size(), 2)
	)
	return {
		"roster": roster,
		"can_start": _can_start(),
		"can_add_bot": roster.size() < max_players,
		"can_remove_bot": not _party.bot_player_ids().is_empty(),
		"max_players": max_players,
	}


func roster() -> Dictionary:
	return _party.snapshot() if _configured else {}


func party_session() -> RefCounted:
	return _party


func input_router() -> RefCounted:
	return _input_router


func clear_input() -> void:
	if _configured:
		_input_router.clear_all()


func refresh() -> void:
	if _configured:
		_refresh()


func _handle_menu(device_id: int) -> String:
	var player_id: int = _party.player_for_device(device_id)
	if player_id < 0:
		if _party.join(device_id) < 0:
			return "full"
		return "joined"
	var slot: Dictionary = _party.snapshot()[player_id]
	if not bool(slot["ready"]):
		_party.set_ready(device_id, true)
		return "ready"
	if _can_start():
		return "start_requested"
	_party.set_ready(device_id, false)
	return "unready"


func _handle_cancel(device_id: int) -> String:
	var player_id: int = _party.player_for_device(device_id)
	if player_id < 0:
		return "ignored"
	var slot: Dictionary = _party.snapshot()[player_id]
	if bool(slot["ready"]):
		_party.set_ready(device_id, false)
		return "unready"
	if not _party.leave(device_id):
		return "ignored"
	return "left"


func _resolve_intent(intent: String, device_id: int) -> String:
	if _policy != null:
		return String(_policy.call("resolve_intent", intent, device_id, _party))
	if intent == "menu":
		return _handle_menu(device_id)
	if intent == "cancel":
		return _handle_cancel(device_id)
	return "ignored"


func _can_start() -> bool:
	return _party.can_start(_min_players, _require_human)


func _refresh() -> void:
	state_changed.emit(lobby_state())


func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo
	return false
