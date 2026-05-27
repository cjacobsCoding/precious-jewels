extends Node2D

enum TurnState { PLAYER, ENEMY, GAME_OVER }

@export var tile_size: int = 64
@export var grid_width: int = 8
@export var grid_height: int = 6

var selected_unit: Node = null
var units: Array = []
var grid: Node = null
var turn_state: TurnState = TurnState.PLAYER

func _ready() -> void:
    grid = $Grid
    grid.setup(Vector2i(grid_width, grid_height), tile_size)
    spawn_units()
    update_unit_tiles()
    update_ui()

func spawn_units() -> void:
    var player_unit = preload("res://scripts/Unit.gd").instantiate()
    player_unit.team = "player"
    player_unit.movement_range = 4
    player_unit.max_hp = 12
    player_unit.attack = 4
    add_child(player_unit)
    units.append(player_unit)
    player_unit.set_tile_position(grid, Vector2i(1, 1))

    var enemy_unit = preload("res://scripts/Unit.gd").instantiate()
    enemy_unit.team = "enemy"
    enemy_unit.movement_range = 3
    enemy_unit.max_hp = 10
    enemy_unit.attack = 3
    add_child(enemy_unit)
    units.append(enemy_unit)
    enemy_unit.set_tile_position(grid, Vector2i(5, 3))

func update_unit_tiles() -> void:
    for unit in units:
        unit.update_label()

func _unhandled_input(event: InputEvent) -> void:
    if turn_state != TurnState.PLAYER or event is not InputEventMouseButton:
        return
    if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
        return

    var click_pos = event.position
    var cell = grid.world_to_grid(click_pos)
    var clicked_unit = get_unit_at(cell)

    if selected_unit:
        if clicked_unit == selected_unit:
            selected_unit.is_selected = false
            selected_unit.update()
            selected_unit = null
            update_ui_message("Selection cleared.")
            return
        if selected_unit.can_move_to(cell, grid) and clicked_unit == null:
            selected_unit.set_tile_position(grid, cell)
            selected_unit.is_selected = false
            selected_unit.update()
            selected_unit = null
            update_unit_tiles()
            update_ui_message("Player moved. Enemy turn incoming.")
            advance_turn()
            return
        if clicked_unit and clicked_unit.team == "player":
            selected_unit.is_selected = false
            clicked_unit.is_selected = true
            selected_unit = clicked_unit
            selected_unit.update()
            update_ui_message("Selected another player unit.")
            return
        selected_unit.is_selected = false
        selected_unit.update()
        selected_unit = null
        update_ui_message("Invalid move. Select a player unit.")
        return

    if clicked_unit and clicked_unit.team == "player":
        selected_unit = clicked_unit
        selected_unit.is_selected = true
        selected_unit.update()
        update_ui_message("Selected player unit. Click a valid tile to move.")
    else:
        update_ui_message("Click a player unit to select it.")

func get_unit_at(tile: Vector2i) -> Node:
    for unit in units:
        if unit.tile_position == tile:
            return unit
    return null

func advance_turn() -> void:
    if turn_state == TurnState.PLAYER:
        turn_state = TurnState.ENEMY
        update_ui()
        call_deferred("enemy_turn")

func enemy_turn() -> void:
    if turn_state != TurnState.ENEMY:
        return
    update_ui_message("Enemy is thinking...")
    await get_tree().create_timer(0.5).timeout

    var enemy_units = get_team_units("enemy")
    for enemy in enemy_units:
        if turn_state != TurnState.ENEMY:
            return
        perform_enemy_action(enemy)
        await get_tree().create_timer(0.2).timeout

    if not check_victory():
        turn_state = TurnState.PLAYER
        update_ui()
        update_ui_message("Your turn. Select a unit.")

func perform_enemy_action(enemy: Node) -> void:
    var target = get_closest_unit(enemy, "player")
    if target == null:
        return

    if enemy.can_attack(target):
        enemy.attack_unit(target)
        update_unit_tiles()
        if not target.is_alive():
            remove_unit(target)
            update_unit_tiles()
        update_ui_message("Enemy attacked!")
        return

    var destination = get_step_toward(enemy, target)
    if destination != null and get_unit_at(destination) == null:
        enemy.set_tile_position(grid, destination)
        update_unit_tiles()
        update_ui_message("Enemy moved.")

func get_team_units(team_name: String) -> Array:
    var result: Array = []
    for unit in units:
        if unit.team == team_name and unit.is_alive():
            result.append(unit)
    return result

func get_closest_unit(from_unit: Node, team_name: String) -> Node:
    var candidates = get_team_units(team_name)
    var best_distance = 999
    var closest = null
    for unit in candidates:
        var distance = abs(unit.tile_position.x - from_unit.tile_position.x) + abs(unit.tile_position.y - from_unit.tile_position.y)
        if distance < best_distance:
            best_distance = distance
            closest = unit
    return closest

func get_step_toward(from_unit: Node, target: Node) -> Vector2i:
    var dx = target.tile_position.x - from_unit.tile_position.x
    var dy = target.tile_position.y - from_unit.tile_position.y
    var step = from_unit.tile_position
    if abs(dx) > abs(dy):
        step.x += sign(dx)
    else:
        step.y += sign(dy)
    if grid.is_in_bounds(step):
        return step
    return null

func remove_unit(team_unit: Node) -> void:
    units.erase(team_unit)
    team_unit.queue_free()
    if selected_unit == team_unit:
        selected_unit = null

func check_victory() -> bool:
    if get_team_units("enemy").empty():
        turn_state = TurnState.GAME_OVER
        update_ui_message("Victory! All enemies defeated.")
        return true
    if get_team_units("player").empty():
        turn_state = TurnState.GAME_OVER
        update_ui_message("Defeat. All player units lost.")
        return true
    return false

func update_ui() -> void:
    if has_node("UI/TurnLabel"):
        $UI/TurnLabel.text = "Turn: %s" % (turn_state == TurnState.PLAYER ? "Player" : turn_state == TurnState.ENEMY ? "Enemy" : "Game Over")
    if has_node("UI/MessageLabel") and turn_state == TurnState.PLAYER:
        $UI/MessageLabel.text = "Select a player unit to move."

func update_ui_message(message: String) -> void:
    if has_node("UI/MessageLabel"):
        $UI/MessageLabel.text = message
