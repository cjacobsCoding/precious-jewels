# Development Plan: Precious Jewels

## Vision
Build a Fire Emblem-style turn-based tactics game with a strong MVP focus. Start by standing up the full game loop with placeholder systems, then iteratively add combat, progression, UI polish, and fun feedback.

## Goals
- Fast MVP: make the game playable from unit selection to enemy turn and victory conditions.
- Keep the fun: ensure each sprint delivers interactive systems and satisfying player choices.
- Build around bones first: establish core structure, then flesh out visuals, data, and polish.

## Sprint 0: Skeleton Game Loop
### Objectives
- Complete basic grid movement.
- Add two teams: player and enemy.
- Implement turn phases: Player Turn, Enemy Turn, Victory/Defeat.
- Add simple unit selection, movement, and action flow.
- Create placeholder UI text for phase and selected unit.

### Deliverables
- `GameManager` handles turn state and phase transitions.
- `Grid` supports bounds checking and path selection.
- `Unit` supports health, movement range, and team affiliation.
- Simple enemy AI: move toward player or wait.
- Win/lose detection when all enemy/player units are defeated.

## Sprint 1: Basic Combat and Interactions
### Objectives
- Add attack actions and health damage.
- Implement weapon range and combat resolution.
- Add unit stats: health, attack, defense, movement.
- Show basic combat feedback.

### Deliverables
- `CombatManager` or expanded `Unit` combat methods.
- Attack/defend logic with hit resolution.
- Health bars or damage numbers.
- Unit death and map removal.
- Simple fog-of-war or line-of-sight is optional.

## Sprint 2: Player UX and Tactical Systems
### Objectives
- Create responsive UI and move/attack highlights.
- Add a turn order or phase indicator.
- Add a simple menu for unit actions: Move, Attack, Wait.
- Improve enemy AI to choose attacks or retreat.

### Deliverables
- Grid highlight for move and attack range.
- Action menu on unit selection.
- Turn-end button and phase transitions.
- Better AI decisions with target selection.
- Sound/visual polish with placeholders.

## Sprint 3: Content and Progression
### Objectives
- Introduce unit classes and growth systems.
- Add multiple levels or maps.
- Add basic unit leveling or class abilities.
- Start building the game world narrative.

### Deliverables
- Unit class definitions and prefab data.
- Level progression system and map loader.
- Simple inventory or equipment system (optional).
- More enemy variety and terrain effects.

## Sprint 4: Polish and Fun Refinement
### Objectives
- Replace placeholder graphics with art or better shapes.
- Add animations, music, and sound effects.
- Refine UI so actions feel clear and rewarding.
- Tune balance around movement, combat, and difficulty.

### Deliverables
- Animated unit sprites and selection feedback.
- Health bars, portraits, and status UI.
- Combat and movement sound cues.
- Refined difficulty curve and pacing.

## Project Workflow
1. Start each sprint with a clear MVP objective.
2. Implement the minimal working feature first.
3. Playtest immediately and adjust.
4. Add polish only after the core loop works.
5. Keep scope small: prioritize interactive play over perfect art.

## How to Use This Plan
- Use `Sprint 0` to get a playable prototype fast.
- After each sprint, test the full loop and confirm it still works.
- When the skeleton is stable, use later sprints to add "flesh" and fun.
- Keep every change centered on making the game feel playable and satisfying.
