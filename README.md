# precious-jewels
Turn-based tactics game prototype built with Godot.

## Setup
1. Install Godot 4.x.
2. Open this folder as a Godot project.
3. Run the main scene: `res://scenes/Main.tscn`.

## Project structure
- `project.godot` — Godot project configuration
- `scenes/Main.tscn` — root scene
- `scripts/GameManager.gd` — game flow and unit selection
- `scripts/Grid.gd` — grid coordinate conversion
- `scripts/Unit.gd` — basic unit logic

## Notes
- Left-click an available player unit to select it.
- Yellow tiles show where the selected unit can move this turn.
- Red tiles show spaces the selected unit can attack after moving.
- Move first, then click an adjacent enemy to attack or right-click to wait.
- Right-click a selected unit to wait, or use the End Turn button to pass to the enemy phase.
- Click any enemy to inspect HP, attack, and defense in the status label.
- This is a scaffold for a Fire Emblem-style tactics game; extend it with combat, turn order, AI, UI, and animation.
- Follow DRY coding practices: avoid duplicate logic and keep gameplay systems centralized.
- Add automated tests for every feature and run tests after each change.

## Testing
- Run `./run_tests.sh` from the repository root.
- If Godot is installed under another name, set `GODOT_CMD` first: `GODOT_CMD=/path/to/godot ./run_tests.sh`.

## Playing a Web Export
- Export the Web build to the `packaged` folder.
- Run `play_packaged.bat` from the project root.
- Keep the server window open while testing; press `Ctrl+C` to stop it.

## Development Plan
See `DEVELOPMENT_PLAN.md` for a sprint-oriented roadmap focused on fast MVP delivery and iterating fun gameplay.
