extends Node


const PartySession := preload("res://addons/couch_party/core/party_session.gd")
const InputRouter := preload("res://addons/couch_party/input/device_input_router.gd")
const PartyLobby := preload("res://addons/couch_party/ui/party_lobby.gd")

var _party: RefCounted
var _input_router: RefCounted
var _lobby: Control
var _status: Label


func _ready() -> void:
	_party = PartySession.new()
	_input_router = InputRouter.new()
	_build_background()
	_lobby = PartyLobby.new()
	add_child(_lobby)
	_lobby.setup(_party, _input_router, {
		"title": "GODOT COUCH PARTY",
		"accent": Color("66d9ef"),
		"max_players": 6,
	})
	_lobby.start_requested.connect(_on_start_requested)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	if _lobby.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
	and event.keycode == KEY_ESCAPE:
		_lobby.open()
		_status.text = ""
		get_viewport().set_input_as_handled()


func _on_start_requested(roster: Dictionary) -> void:
	_lobby.close()
	var humans := 0
	var bots := 0
	for slot: Dictionary in roster.values():
		if String(slot["control_kind"]) == "bot":
			bots += 1
		else:
			humans += 1
	_status.text = "PARTY READY\n%d HUMAN%s  •  %d BOT%s\n\nESC returns to the lobby" % [
		humans,
		"" if humans == 1 else "S",
		bots,
		"" if bots == 1 else "S",
	]


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	_lobby.device_connection_changed(device_id, connected)


func seed_preview_roster() -> void:
	_party.join(-1)
	_party.set_ready(-1, true)
	_party.join(0)
	_party.add_bot("easy")
	_party.add_bot("hard")
	_lobby.open()


func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color("080d17")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_status = Label.new()
	_status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 30)
	_status.add_theme_color_override("font_color", Color("d9f7ff"))
	background.add_child(_status)
