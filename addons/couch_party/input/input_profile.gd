class_name CouchPartyInputProfile
extends RefCounted


const KEYBOARD_PRIMARY: int = -1
const DEFAULT_DEADZONE: float = 0.22

var deadzone: float = DEFAULT_DEADZONE

var _controller_actions: Dictionary = {}
var _keyboard_bindings: Dictionary = {}
var _keyboard_devices: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	deadzone = clampf(float(config.get("deadzone", DEFAULT_DEADZONE)), 0.0, 0.95)
	set_controller_bindings({
		"primary": JOY_BUTTON_X,
		"secondary": JOY_BUTTON_A,
		"tertiary": JOY_BUTTON_Y,
		"menu": JOY_BUTTON_START,
		"cancel": JOY_BUTTON_B,
	})
	add_keyboard_layout(KEYBOARD_PRIMARY, {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_up": KEY_W,
		"move_down": KEY_S,
		"primary": KEY_E,
		"secondary": KEY_SPACE,
		"tertiary": KEY_Q,
		"menu": KEY_ENTER,
		"cancel": KEY_ESCAPE,
	})


func set_controller_bindings(bindings: Dictionary) -> void:
	_controller_actions.clear()
	for action_variant: Variant in bindings:
		var action := String(action_variant)
		if action not in _semantic_actions():
			continue
		_controller_actions[int(bindings[action_variant])] = action


func add_keyboard_layout(device_id: int, bindings: Dictionary) -> bool:
	if device_id >= 0:
		return false
	remove_keyboard_layout(device_id)
	_keyboard_devices[device_id] = true
	for action_variant: Variant in bindings:
		var action := String(action_variant)
		if action not in _all_actions():
			continue
		_keyboard_bindings[int(bindings[action_variant])] = {
			"device_id": device_id,
			"action": action,
		}
	return true


func remove_keyboard_layout(device_id: int) -> bool:
	if not _keyboard_devices.erase(device_id):
		return false
	var keys_to_remove: Array[int] = []
	for key_variant: Variant in _keyboard_bindings:
		var key := int(key_variant)
		if int(_keyboard_bindings[key]["device_id"]) == device_id:
			keys_to_remove.append(key)
	for key: int in keys_to_remove:
		_keyboard_bindings.erase(key)
	return true


func controller_action(button_index: int) -> String:
	return String(_controller_actions.get(button_index, ""))


func keyboard_binding(key: Key) -> Dictionary:
	return (_keyboard_bindings.get(key, {}) as Dictionary).duplicate(true)


func has_keyboard_device(device_id: int) -> bool:
	return _keyboard_devices.has(device_id)


func keyboard_device_ids() -> Array[int]:
	var result: Array[int] = []
	for device_id: int in _keyboard_devices:
		result.append(device_id)
	result.sort()
	return result


func _semantic_actions() -> Array[String]:
	return ["primary", "secondary", "tertiary", "menu", "cancel"]


func _all_actions() -> Array[String]:
	return ["move_left", "move_right", "move_up", "move_down"] + _semantic_actions()
