class_name CouchPartyLobby
extends Control


signal roster_changed(roster: Dictionary)
signal start_requested(roster: Dictionary)

const PartyLobbyView := preload("res://addons/couch_party/ui/party_lobby_view.gd")

var _party: RefCounted
var _input_router: RefCounted
var _view: Control
var _configured: bool = false


func setup(party: RefCounted, input_router: RefCounted, options: Dictionary = {}) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_party = party
	_input_router = input_router
	if is_instance_valid(_view):
		_view.queue_free()
	_view = PartyLobbyView.new()
	add_child(_view)
	_view.setup(options)
	_view.add_bot_requested.connect(add_bot)
	_view.remove_bot_requested.connect(remove_last_bot)
	_view.start_requested.connect(request_start)
	_configured = true
	_refresh()


func _input(event: InputEvent) -> void:
	if not visible or not _configured:
		return
	var action := handle_event(event)
	if not action.is_empty() and action != "ignored":
		get_viewport().set_input_as_handled()


func handle_event(event: InputEvent) -> String:
	if not _configured:
		return "ignored"
	_input_router.ingest(event)
	var device_id: int = _input_router.device_for_event(event)
	if device_id == _input_router.NO_DEVICE:
		return "ignored"
	if not _is_press_event(event):
		return "ignored"
	var frame: Dictionary = _input_router.frame_for_device(device_id)
	if bool(frame["menu_pressed"]):
		return _handle_menu(device_id)
	if bool(frame["cancel_pressed"]):
		return _handle_cancel(device_id)
	return "ignored"


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
	return action


func add_bot(difficulty: String) -> int:
	if not _configured:
		return -1
	var player_id: int = _party.add_bot(difficulty)
	if player_id > 0:
		_refresh()
	return player_id


func remove_last_bot() -> bool:
	if not _configured:
		return false
	var bot_ids: Array[int] = _party.bot_player_ids()
	if bot_ids.is_empty() or not _party.remove_bot(bot_ids.back()):
		return false
	_refresh()
	return true


func request_start() -> bool:
	if not _configured or not _party.can_start():
		return false
	start_requested.emit(_party.snapshot())
	return true


func open() -> void:
	show()
	_refresh()


func close() -> void:
	hide()
	_input_router.clear_all()


func roster() -> Dictionary:
	return _party.snapshot() if _configured else {}


func party_session() -> RefCounted:
	return _party


func input_router() -> RefCounted:
	return _input_router


func _handle_menu(device_id: int) -> String:
	var player_id: int = _party.player_for_device(device_id)
	if player_id < 0:
		if _party.join(device_id) < 0:
			return "full"
		_refresh()
		return "joined"
	var slot: Dictionary = _party.snapshot()[player_id]
	if not bool(slot["ready"]):
		_party.set_ready(device_id, true)
		_refresh()
		return "ready"
	if _party.can_start():
		start_requested.emit(_party.snapshot())
		return "start_requested"
	_party.set_ready(device_id, false)
	_refresh()
	return "unready"


func _handle_cancel(device_id: int) -> String:
	var player_id: int = _party.player_for_device(device_id)
	if player_id < 0:
		return "ignored"
	var slot: Dictionary = _party.snapshot()[player_id]
	if bool(slot["ready"]):
		_party.set_ready(device_id, false)
		_refresh()
		return "unready"
	if not _party.leave(device_id):
		return "ignored"
	_input_router.clear_device(device_id)
	_refresh()
	return "left"


func _refresh() -> void:
	if not _configured:
		return
	var snapshot: Dictionary = _party.snapshot()
	_view.render(snapshot)
	roster_changed.emit(snapshot)


func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo
	return false
