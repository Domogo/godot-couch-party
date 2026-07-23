class_name CouchPartyLobby
extends Control


signal roster_changed(roster: Dictionary)
signal start_requested(roster: Dictionary)

const PartyLobbyController := preload(
	"res://addons/couch_party/ui/party_lobby_controller.gd"
)
const PartyLobbyView := preload("res://addons/couch_party/ui/party_lobby_view.gd")

var _controller: RefCounted
var _view: Control
var _configured: bool = false


func setup(
	party: RefCounted,
	input_router: RefCounted,
	options: Dictionary = {},
) -> bool:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_configured = false
	if is_instance_valid(_view):
		_view.queue_free()
	_view = _create_view(options)
	if _view == null or not _view.has_method("render_lobby") and not _view.has_method("render"):
		push_error("CouchPartyLobby view must implement render_lobby(state) or render(roster).")
		return false
	add_child(_view)
	if _view.has_method("setup"):
		_view.call("setup", _view_options(options))
	if _view.has_signal("add_bot_requested"):
		_view.connect("add_bot_requested", add_bot)
	if _view.has_signal("remove_bot_requested"):
		_view.connect("remove_bot_requested", remove_last_bot)
	if _view.has_signal("start_requested"):
		_view.connect("start_requested", request_start)

	_controller = PartyLobbyController.new()
	_controller.state_changed.connect(_present_state)
	_controller.start_requested.connect(_forward_start_request)
	if not _controller.setup(party, input_router, options):
		return false
	_configured = true
	return true


func _input(event: InputEvent) -> void:
	if not visible or not _configured:
		return
	var action := handle_event(event)
	if action == "confirm_requested":
		action = "confirmed" if _activate_focused_button() else "ignored"
	if not action.is_empty() and action != "ignored":
		get_viewport().set_input_as_handled()


func handle_event(event: InputEvent) -> String:
	return _controller.handle_event(event) if _configured else "ignored"


func device_connection_changed(device_id: int, connected: bool) -> String:
	return (
		_controller.device_connection_changed(device_id, connected)
		if _configured
		else "ignored"
	)


func add_bot(difficulty: String) -> int:
	return _controller.add_bot(difficulty) if _configured else -1


func remove_last_bot() -> bool:
	return _controller.remove_last_bot() if _configured else false


func request_start() -> bool:
	return _controller.request_start() if _configured else false


func open() -> void:
	show()
	if _configured:
		_controller.refresh()


func close() -> void:
	hide()
	if _configured:
		_controller.clear_input()


func lobby_state() -> Dictionary:
	return _controller.lobby_state() if _configured else {}


func roster() -> Dictionary:
	return _controller.roster() if _configured else {}


func party_session() -> RefCounted:
	return _controller.party_session() if _configured else null


func input_router() -> RefCounted:
	return _controller.input_router() if _configured else null


func controller() -> RefCounted:
	return _controller


func _activate_focused_button() -> bool:
	var button := get_viewport().gui_get_focus_owner() as Button
	if button == null or not is_ancestor_of(button):
		return false
	if not button.is_visible_in_tree() or button.disabled:
		return false
	button.pressed.emit()
	return true


func _create_view(options: Dictionary) -> Control:
	var supplied_view: Variant = options.get("view")
	if supplied_view is Control:
		var control := supplied_view as Control
		if control.get_parent() != null:
			push_error("CouchPartyLobby custom view must not already have a parent.")
			return null
		return control
	var supplied_scene: Variant = options.get("view_scene")
	if supplied_scene is PackedScene:
		var instance: Node = (supplied_scene as PackedScene).instantiate()
		if instance is Control:
			return instance as Control
		instance.queue_free()
		push_error("CouchPartyLobby view_scene root must extend Control.")
		return null
	return PartyLobbyView.new()


func _view_options(options: Dictionary) -> Dictionary:
	var result := options.duplicate(true)
	result.erase("view")
	result.erase("view_scene")
	result.erase("policy")
	return result


func _present_state(state: Dictionary) -> void:
	if not is_instance_valid(_view):
		return
	if _view.has_method("render_lobby"):
		_view.call("render_lobby", state)
	else:
		_view.call("render", state["roster"])
	roster_changed.emit((state["roster"] as Dictionary).duplicate(true))


func _forward_start_request(roster: Dictionary) -> void:
	start_requested.emit(roster)
