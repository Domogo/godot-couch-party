# Changelog

All notable changes follow [Semantic Versioning](https://semver.org/).

## 0.1.3 — 2026-07-23

- Made South/A join and ready an unassigned controller before activating focused lobby controls.
- Updated the default lobby prompts and empty-slot copy to teach the one-button join flow.

## 0.1.2 — 2026-07-23

- Added an explicit controller confirmation request to the headless lobby controller.
- Made the default and custom lobby views activate focused buttons from South/A without relying on a host project's `ui_accept` action.
- Preserved Start as the isolated per-device join and ready command.

## 0.1.1 — 2026-07-23

- Added a headless lobby controller with capability state and optional game-owned policies.
- Added injectable lobby views and scenes while preserving the default lobby interface.
- Added configurable semantic input actions beyond the built-in action set.
- Improved the default lobby's responsive layout and capability-driven controls.

## 0.1.0 — 2026-07-19

- Added stable device-to-player assignment for configurable two-to-eight-player parties.
- Added human, bot, empty, ready, disconnect, reconnect, and bot-difficulty roster behavior.
- Added event-driven, per-device semantic input frames with configurable controller and keyboard profiles.
- Added a reusable six-slot join/ready lobby with bot controls.
- Added a runnable example and headless verification suite for Godot 4.7.
