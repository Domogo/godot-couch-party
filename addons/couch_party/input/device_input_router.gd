class_name CouchPartyInputRouter
extends RefCounted


const InputProfile := preload("res://addons/couch_party/input/input_profile.gd")

const KEYBOARD_PRIMARY: int = -1
const NO_DEVICE: int = -1_000_000

var _profile: RefCounted = InputProfile.new()
var _axes: Dictionary = {}
var _held: Dictionary = {}
var _pending: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	var configured_profile: Variant = config.get("profile")
	if configured_profile is RefCounted:
		_profile = configured_profile as RefCounted
	else:
		_profile = InputProfile.new(config)


func ingest(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		_ingest_motion(event as InputEventJoypadMotion)
	elif event is InputEventJoypadButton:
		_ingest_button(event as InputEventJoypadButton)
	elif event is InputEventKey and not event.echo:
		_ingest_key(event as InputEventKey)


func frame_for_device(device_id: int) -> Dictionary:
	var held_actions: Dictionary = _held.get(device_id, {}) as Dictionary
	var move := _keyboard_move(held_actions) if _profile.has_keyboard_device(device_id) else _controller_move(device_id)
	if move.length() < float(_profile.deadzone):
		move = Vector2.ZERO
	else:
		move = move.limit_length(1.0)
	var frame := {
		"move": move,
		"aim": move,
	}
	var pending_actions: Dictionary = _pending.get(device_id, {}) as Dictionary
	for action: String in ["primary", "secondary", "tertiary", "menu", "cancel"]:
		frame["%s_held" % action] = bool(held_actions.get(action, false))
		frame["%s_pressed" % action] = bool(pending_actions.get(action, false))
		pending_actions[action] = false
	_pending[device_id] = pending_actions
	return frame


func device_for_event(event: InputEvent) -> int:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var key: Key = key_event.keycode if key_event.keycode != KEY_NONE else key_event.physical_keycode
		var binding: Dictionary = _profile.keyboard_binding(key)
		return int(binding.get("device_id", NO_DEVICE))
	return NO_DEVICE


func clear_device(device_id: int) -> void:
	_axes.erase(device_id)
	_held.erase(device_id)
	_pending.erase(device_id)


func clear_all() -> void:
	_axes.clear()
	_held.clear()
	_pending.clear()


func _ingest_motion(event: InputEventJoypadMotion) -> void:
	if event.axis not in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		return
	var device_axes: Dictionary = _axes.get(event.device, {}) as Dictionary
	device_axes[event.axis] = event.axis_value
	_axes[event.device] = device_axes


func _ingest_button(event: InputEventJoypadButton) -> void:
	var action: String = _profile.controller_action(event.button_index)
	if action.is_empty():
		return
	_set_action(event.device, action, event.pressed)


func _ingest_key(event: InputEventKey) -> void:
	var key: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	var binding: Dictionary = _profile.keyboard_binding(key)
	if binding.is_empty():
		return
	_set_action(int(binding["device_id"]), String(binding["action"]), event.pressed)


func _set_action(device_id: int, action: String, pressed: bool) -> void:
	var held_actions: Dictionary = _held.get(device_id, {}) as Dictionary
	var pending_actions: Dictionary = _pending.get(device_id, {}) as Dictionary
	if pressed and not bool(held_actions.get(action, false)) and not action.begins_with("move_"):
		pending_actions[action] = true
	held_actions[action] = pressed
	_held[device_id] = held_actions
	_pending[device_id] = pending_actions


func _keyboard_move(held_actions: Dictionary) -> Vector2:
	return Vector2(
		float(int(bool(held_actions.get("move_right", false))))
			- float(int(bool(held_actions.get("move_left", false)))),
		float(int(bool(held_actions.get("move_down", false))))
			- float(int(bool(held_actions.get("move_up", false)))),
	).normalized()


func _controller_move(device_id: int) -> Vector2:
	var device_axes: Dictionary = _axes.get(device_id, {}) as Dictionary
	return Vector2(
		float(device_axes.get(JOY_AXIS_LEFT_X, 0.0)),
		float(device_axes.get(JOY_AXIS_LEFT_Y, 0.0)),
	)
