# Godot Couch Party

Version 0.1.3. Runtime-only Godot 4 addon for local parties of human and bot players.

This folder is self-contained. Copy `addons/couch_party/` into a Godot project; no editor plugin needs to be enabled.

The public modules are:

- `core/party_session.gd` for stable roster identity, readiness, bots, and reconnects
- `input/device_input_router.gd` for isolated per-device semantic input frames
- `ui/party_lobby_controller.gd` for headless lobby intent and capability state
- `ui/party_lobby.gd` for an injectable or default lobby presentation

Lobby views implement `render_lobby(state)` and may emit `add_bot_requested`, `remove_bot_requested`, or `start_requested`. Pass a view with the `view` option or a `PackedScene` with `view_scene`. Pass a `RefCounted` `policy` with `resolve_intent(intent, device_id, party)` to customize join, ready, start, and leave behavior.

Input profiles accept `extra_actions`; each configured name appears in input frames as `<name>_pressed` and `<name>_held`.

The lobby treats the profile's secondary controller action (South/A by default) as a device-aware
join and confirmation action. It joins and readies an unassigned device, then explicitly confirms
focused controls after that device has joined. Menu/Start remains a join and ready shortcut.

Complete documentation and examples are available at [github.com/Domogo/godot-couch-party](https://github.com/Domogo/godot-couch-party).
