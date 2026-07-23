class_name CouchPartyLobbyView
extends Control


signal add_bot_requested(difficulty: String)
signal remove_bot_requested
signal start_requested

const DEFAULT_ACCENT := Color("66d9ef")

var _title: String = "COUCH PARTY"
var _max_players: int = 6
var _accent: Color = DEFAULT_ACCENT
var _built: bool = false
var _title_label: Label
var _slot_labels: Array[Label] = []
var _slot_grid: GridContainer
var _bot_buttons: Array[Button] = []
var _remove_bot_button: Button
var _start_button: Button


func _ready() -> void:
	_build()


func setup(options: Dictionary = {}) -> void:
	_title = String(options.get("title", _title))
	_max_players = clampi(int(options.get("max_players", _max_players)), 2, 8)
	_accent = options.get("accent", _accent) as Color
	_build(true)


func render(roster: Dictionary) -> void:
	render_lobby({
		"roster": roster,
		"can_start": _roster_can_start(roster),
		"can_add_bot": roster.size() < _max_players,
		"can_remove_bot": _roster_has_bot(roster),
		"max_players": _max_players,
	})


func render_lobby(state: Dictionary) -> void:
	var state_max_players := clampi(int(state.get("max_players", _max_players)), 2, 8)
	if state_max_players != _max_players:
		_max_players = state_max_players
		_build(true)
	else:
		_build()
	var roster: Dictionary = state.get("roster", {}) as Dictionary
	for player_index: int in _max_players:
		var player_id := player_index + 1
		var text := "P%d  •  EMPTY  •  PRESS A / CROSS TO JOIN" % player_id
		if roster.has(player_id):
			var slot: Dictionary = roster[player_id]
			if String(slot.get("control_kind", "human")) == "bot":
				text = "P%d  •  CPU  •  %s  •  READY" % [
					player_id,
					String(slot.get("bot_difficulty", "medium")).to_upper(),
				]
			else:
				var connected := bool(slot.get("connected", false))
				var ready := bool(slot.get("ready", false))
				text = "P%d  •  %s  •  %s" % [
					player_id,
					_device_label(int(slot.get("device_id", -1))),
					("READY" if ready else "JOINED") if connected else "DISCONNECTED",
				]
		_slot_labels[player_index].text = text
		_slot_labels[player_index].modulate = Color.WHITE if roster.has(player_id) else Color("8490a0")
	var can_add_bot := bool(state.get("can_add_bot", roster.size() < _max_players))
	for button: Button in _bot_buttons:
		button.disabled = not can_add_bot
	_remove_bot_button.disabled = not bool(state.get("can_remove_bot", _roster_has_bot(roster)))
	_start_button.disabled = not bool(state.get("can_start", _roster_can_start(roster)))


func slot_texts() -> Array[String]:
	var result: Array[String] = []
	for label: Label in _slot_labels:
		result.append(label.text)
	return result


func _build(force_rebuild: bool = false) -> void:
	if _built and not force_rebuild:
		return
	if _built:
		for child: Node in get_children():
			child.free()
		_slot_labels.clear()
		_bot_buttons.clear()
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not resized.is_connected(_refresh_responsive_layout):
		resized.connect(_refresh_responsive_layout)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.055, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_top = 0.075
	panel.anchor_right = 0.92
	panel.anchor_bottom = 0.925
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("111827")
	panel_style.border_color = _accent.darkened(0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.set_content_margin_all(26.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	_title_label = Label.new()
	_title_label.text = _title
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", _accent)
	content.add_child(_title_label)

	var instruction := Label.new()
	instruction.text = "A / CROSS: JOIN / SELECT   •   START: READY   •   B / ESC: LEAVE"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 13)
	instruction.add_theme_color_override("font_color", Color("aeb8c8"))
	content.add_child(instruction)

	_slot_grid = GridContainer.new()
	_slot_grid.columns = 2
	_slot_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slot_grid.add_theme_constant_override("h_separation", 12)
	_slot_grid.add_theme_constant_override("v_separation", 12)
	content.add_child(_slot_grid)
	for player_index: int in _max_players:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(260.0, 74.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("1b2535")
		card_style.border_color = Color("344258")
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(8)
		card_style.set_content_margin_all(16.0)
		card.add_theme_stylebox_override("panel", card_style)
		_slot_grid.add_child(card)
		var label := Label.new()
		label.text = "P%d  •  EMPTY  •  PRESS A / CROSS TO JOIN" % (player_index + 1)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		card.add_child(label)
		_slot_labels.append(label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	for difficulty: String in ["easy", "medium", "hard"]:
		var bot_button := Button.new()
		bot_button.text = "+ %s BOT" % difficulty.to_upper()
		bot_button.pressed.connect(_emit_add_bot.bind(difficulty))
		buttons.add_child(bot_button)
		_bot_buttons.append(bot_button)
		if difficulty == "easy":
			bot_button.call_deferred("grab_focus")
	_remove_bot_button = Button.new()
	_remove_bot_button.text = "− BOT"
	_remove_bot_button.pressed.connect(remove_bot_requested.emit)
	buttons.add_child(_remove_bot_button)
	_start_button = Button.new()
	_start_button.text = "START MATCH"
	_start_button.pressed.connect(start_requested.emit)
	buttons.add_child(_start_button)
	_refresh_responsive_layout()


func _emit_add_bot(difficulty: String) -> void:
	add_bot_requested.emit(difficulty)


func _device_label(device_id: int) -> String:
	if device_id == -1:
		return "KEYBOARD"
	if device_id < -1:
		return "KEYBOARD %d" % absi(device_id)
	return "CONTROLLER %d" % (device_id + 1)


func _refresh_responsive_layout() -> void:
	if is_instance_valid(_slot_grid):
		_slot_grid.columns = 1 if size.x > 0.0 and size.x < 720.0 else 2


func _roster_can_start(roster: Dictionary) -> bool:
	if roster.size() < 2:
		return false
	var has_human := false
	for slot_variant: Variant in roster.values():
		var slot: Dictionary = slot_variant as Dictionary
		if String(slot.get("control_kind", "human")) == "human":
			has_human = true
			if not bool(slot.get("connected", false)) or not bool(slot.get("ready", false)):
				return false
		elif not bool(slot.get("ready", false)):
			return false
	return has_human


func _roster_has_bot(roster: Dictionary) -> bool:
	for slot_variant: Variant in roster.values():
		var slot: Dictionary = slot_variant as Dictionary
		if String(slot.get("control_kind", "human")) == "bot":
			return true
	return false
