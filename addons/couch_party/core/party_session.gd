class_name CouchPartySession
extends RefCounted


const KEYBOARD_PRIMARY: int = -1
const DEFAULT_MAX_PLAYERS: int = 6
const BOT_EASY: String = "easy"
const BOT_MEDIUM: String = "medium"
const BOT_HARD: String = "hard"
const BOT_DIFFICULTIES: Array[String] = [BOT_EASY, BOT_MEDIUM, BOT_HARD]

var _max_players: int = DEFAULT_MAX_PLAYERS
var _slots: Dictionary = {}
var _players_by_device: Dictionary = {}
var _keyboard_devices: Dictionary = {KEYBOARD_PRIMARY: true}


func _init(config: Dictionary = {}) -> void:
	_max_players = maxi(2, int(config.get("max_players", DEFAULT_MAX_PLAYERS)))
	_keyboard_devices.clear()
	var configured_keyboards: Array = config.get("keyboard_device_ids", [KEYBOARD_PRIMARY]) as Array
	for device_variant: Variant in configured_keyboards:
		var device_id := int(device_variant)
		if device_id < 0:
			_keyboard_devices[device_id] = true


func join(device_id: int) -> int:
	if device_id < 0 and not _keyboard_devices.has(device_id):
		return -1
	if _players_by_device.has(device_id):
		var existing_player_id := int(_players_by_device[device_id])
		_slots[existing_player_id]["connected"] = true
		return existing_player_id
	if _slots.size() >= _max_players:
		return -1
	var player_id := _next_player_id()
	_players_by_device[device_id] = player_id
	_slots[player_id] = {
		"player_id": player_id,
		"control_kind": "human",
		"device_id": device_id,
		"connected": true,
		"ready": false,
		"bot_difficulty": "",
	}
	return player_id


func snapshot() -> Dictionary:
	return _slots.duplicate(true)


func max_players() -> int:
	return _max_players


func set_ready(device_id: int, ready: bool) -> bool:
	var player_id := player_for_device(device_id)
	if player_id < 0 or not bool(_slots[player_id]["connected"]):
		return false
	_slots[player_id]["ready"] = ready
	return true


func toggle_ready(device_id: int) -> bool:
	var player_id := player_for_device(device_id)
	if player_id < 0:
		return false
	return set_ready(device_id, not bool(_slots[player_id]["ready"]))


func add_bot(difficulty: String = BOT_MEDIUM) -> int:
	var normalized_difficulty := difficulty.to_lower()
	if normalized_difficulty not in BOT_DIFFICULTIES or _slots.size() >= _max_players:
		return -1
	var player_id := _next_player_id()
	_slots[player_id] = {
		"player_id": player_id,
		"control_kind": "bot",
		"connected": true,
		"ready": true,
		"bot_difficulty": normalized_difficulty,
	}
	return player_id


func remove_bot(player_id: int) -> bool:
	if not _slots.has(player_id) or String(_slots[player_id]["control_kind"]) != "bot":
		return false
	_slots.erase(player_id)
	return true


func set_bot_difficulty(player_id: int, difficulty: String) -> bool:
	var normalized_difficulty := difficulty.to_lower()
	if not _slots.has(player_id) \
	or String(_slots[player_id]["control_kind"]) != "bot" \
	or normalized_difficulty not in BOT_DIFFICULTIES:
		return false
	_slots[player_id]["bot_difficulty"] = normalized_difficulty
	return true


func can_start(min_players: int = 2, require_human: bool = true) -> bool:
	if _slots.size() < maxi(1, min_players):
		return false
	var has_human := false
	for slot: Dictionary in _slots.values():
		if String(slot["control_kind"]) == "human":
			has_human = true
			if not bool(slot["connected"]) or not bool(slot["ready"]):
				return false
		elif not bool(slot["ready"]):
			return false
	return has_human or not require_human


func disconnect_device(device_id: int) -> bool:
	var player_id := player_for_device(device_id)
	if player_id < 0:
		return false
	_slots[player_id]["connected"] = false
	_slots[player_id]["ready"] = false
	return true


func reconnect(device_id: int) -> int:
	return join(device_id)


func leave(device_id: int) -> bool:
	var player_id := player_for_device(device_id)
	if player_id < 0:
		return false
	_players_by_device.erase(device_id)
	_slots.erase(player_id)
	return true


func player_for_device(device_id: int) -> int:
	return int(_players_by_device.get(device_id, -1))


func device_for_player(player_id: int) -> int:
	if not _slots.has(player_id) or String(_slots[player_id]["control_kind"]) != "human":
		return -2
	return int(_slots[player_id]["device_id"])


func is_player_connected(player_id: int) -> bool:
	return _slots.has(player_id) and bool(_slots[player_id]["connected"])


func human_player_ids(connected_only: bool = false) -> Array[int]:
	return _player_ids_for_kind("human", connected_only)


func bot_player_ids() -> Array[int]:
	return _player_ids_for_kind("bot", false)


func player_ids() -> Array[int]:
	var result: Array[int] = []
	for player_id: int in _slots:
		result.append(player_id)
	result.sort()
	return result


func _next_player_id() -> int:
	for player_id: int in range(1, _max_players + 1):
		if not _slots.has(player_id):
			return player_id
	return -1


func _player_ids_for_kind(kind: String, connected_only: bool) -> Array[int]:
	var result: Array[int] = []
	for player_id: int in _slots:
		var slot: Dictionary = _slots[player_id]
		if String(slot["control_kind"]) == kind \
		and (not connected_only or bool(slot["connected"])):
			result.append(player_id)
	result.sort()
	return result
