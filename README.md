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
- Click on a unit to select it, then click a valid tile to move.
- This is a scaffold for a Fire Emblem-style tactics game; extend it with combat, turn order, AI, UI, and animation.
