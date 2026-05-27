extends Node2D

enum TurnState { PLAYER, ENEMY, GAME_OVER }

@export var tile_size: int = 64
@export var grid_width: int = 8
@export var grid_height: int = 6

var selected_unit: Node = null
var units: Array = []
var grid: Node = null
var turn_state: TurnState = TurnState.PLAYER
var turn_count: int = 1

func _ready() -> void:
    if has_node("Grid"):
        grid = $Grid
        grid.setup(Vector2i(grid_width, grid_height), tile_size)
        spawn_units()
        update_unit_tiles()
        setup_ui()
        update_ui()
    elif grid != null:
        spawn_units()
        update_unit_tiles()
        setup_ui()
        update_ui()

func spawn_units() -> void:
    var player_unit = preload("res://scripts/Unit.gd").new()
    player_unit.team = "player"
    player_unit.movement_range = 4
    player_unit.max_hp = 12
    player_unit.hp = 12
    player_unit.attack = 4
    add_child(player_unit)
    units.append(player_unit)
    player_unit.set_tile_position(grid, Vector2i(1, 1))

    var player_unit_2 = preload("res://scripts/Unit.gd").new()
    player_unit_2.team = "player"
    player_unit_2.movement_range = 3
    player_unit_2.max_hp = 10
    player_unit_2.hp = 10
    player_unit_2.attack = 5
    add_child(player_unit_2)
    units.append(player_unit_2)
    player_unit_2.set_tile_position(grid, Vector2i(1, 3))

    var enemy_unit = preload("res://scripts/Unit.gd").new()
    enemy_unit.team = "enemy"
    enemy_unit.movement_range = 3
    enemy_unit.max_hp = 10
    enemy_unit.hp = 10
    enemy_unit.attack = 3
    add_child(enemy_unit)
    units.append(enemy_unit)
    enemy_unit.set_tile_position(grid, Vector2i(5, 3))

    var enemy_unit_2 = preload("res://scripts/Unit.gd").new()
    enemy_unit_2.team = "enemy"
    enemy_unit_2.movement_range = 3
    enemy_unit_2.max_hp = 8
    enemy_unit_2.hp = 8
    enemy_unit_2.attack = 4
    add_child(enemy_unit_2)
    units.append(enemy_unit_2)
    enemy_unit_2.set_tile_position(grid, Vector2i(6, 1))

func update_unit_tiles() -> void:
    for unit in units:
        unit.update_label()

func _unhandled_input(event: InputEvent) -> void:
    if turn_state != TurnState.PLAYER or not (event is InputEventMouseButton):
        return
    if not event.pressed:
        return
    if event.button_index == MOUSE_BUTTON_RIGHT and selected_unit:
        finish_player_action(selected_unit, "Unit waited.")
        maybe_finish_player_turn()
        return
    if event.button_index != MOUSE_BUTTON_LEFT:
        return

    var click_pos = event.position
    var cell = grid.world_to_grid(click_pos)
    var clicked_unit = get_unit_at(cell)

    if selected_unit:
        if clicked_unit == selected_unit:
            clear_selection()
            update_ui_message("Selection cleared.")
            return
        if clicked_unit and clicked_unit.team == "enemy":
            if selected_unit.can_attack(clicked_unit):
                selected_unit.attack_unit(clicked_unit)
                finish_player_action(selected_unit, "Player attacked.")
                if not clicked_unit.is_alive():
                    remove_unit(clicked_unit)
                    update_ui_message("Enemy defeated.")
                if not check_victory():
                    maybe_finish_player_turn()
                return
            update_ui_message("Enemy is out of attack range.")
            return
        if selected_unit.can_move_to(cell, grid) and clicked_unit == null:
            selected_unit.set_tile_position(grid, cell)
            finish_player_action(selected_unit, "Player moved.")
            maybe_finish_player_turn()
            return
        if clicked_unit and clicked_unit.team == "player" and not clicked_unit.has_acted:
            selected_unit.is_selected = false
            selected_unit.queue_redraw()
            clicked_unit.is_selected = true
            selected_unit = clicked_unit
            selected_unit.queue_redraw()
            show_move_highlights(selected_unit)
            update_ui_message("Selected another player unit.")
            return
        update_ui_message("Invalid action. Choose a highlighted tile or adjacent enemy.")
        return

    if clicked_unit and clicked_unit.team == "player" and not clicked_unit.has_acted:
        selected_unit = clicked_unit
        selected_unit.is_selected = true
        selected_unit.queue_redraw()
        show_move_highlights(selected_unit)
        update_ui_message("Selected player unit. Move to a highlight or attack an adjacent enemy.")
    elif clicked_unit and clicked_unit.team == "player":
        update_ui_message("That unit has already acted this turn.")
    else:
        update_ui_message("Click an available player unit to select it.")

func get_unit_at(tile: Vector2i) -> Node:
    for unit in units:
        if unit.tile_position == tile:
            return unit
    return null

func advance_turn() -> void:
    if turn_state == TurnState.PLAYER:
        clear_selection()
        reset_team_actions("enemy")
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
        turn_count += 1
        reset_team_actions("player")
        turn_state = TurnState.PLAYER
        update_ui()
        update_ui_message("Your turn. Select a unit.")

func perform_enemy_action(enemy: Node) -> void:
    var target = get_closest_unit(enemy, "player")
    if target == null:
        return

    if enemy.can_attack(target):
        enemy.attack_unit(target)
        enemy.has_acted = true
        update_unit_tiles()
        if not target.is_alive():
            remove_unit(target)
            update_unit_tiles()
        update_ui_message("Enemy attacked!")
        return

    var destination = get_step_toward(enemy, target)
    if destination != null and get_unit_at(destination) == null:
        enemy.set_tile_position(grid, destination)
        enemy.has_acted = true
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
    return from_unit.tile_position

func remove_unit(team_unit: Node) -> void:
    units.erase(team_unit)
    team_unit.queue_free()
    if selected_unit == team_unit:
        selected_unit = null

func check_victory() -> bool:
    if get_team_units("enemy").is_empty():
        turn_state = TurnState.GAME_OVER
        update_ui()
        update_ui_message("Victory! All enemies defeated.")
        return true
    if get_team_units("player").is_empty():
        turn_state = TurnState.GAME_OVER
        update_ui()
        update_ui_message("Defeat. All player units lost.")
        return true
    return false

func update_ui() -> void:
    if has_node("UI/TurnLabel"):
        var turn_text: String
        if turn_state == TurnState.PLAYER:
            turn_text = "Player"
        elif turn_state == TurnState.ENEMY:
            turn_text = "Enemy"
        else:
            turn_text = "Game Over"
        $UI/TurnLabel.text = "Turn %d: %s" % [turn_count, turn_text]
    if has_node("UI/MessageLabel") and turn_state == TurnState.PLAYER:
        $UI/MessageLabel.text = "Select a player unit to move."

func update_ui_message(message: String) -> void:
    if has_node("UI/MessageLabel"):
        $UI/MessageLabel.text = message

func setup_ui() -> void:
    if has_node("UI/EndTurnButton"):
        var button = $UI/EndTurnButton
        if not button.pressed.is_connected(_on_end_turn_pressed):
            button.pressed.connect(_on_end_turn_pressed)

func _on_end_turn_pressed() -> void:
    if turn_state != TurnState.PLAYER:
        return
    update_ui_message("Ending player turn.")
    advance_turn()

func finish_player_action(unit: Node, message: String) -> void:
    unit.has_acted = true
    clear_selection()
    update_unit_tiles()
    update_ui_message(message)

func clear_selection() -> void:
    if selected_unit:
        selected_unit.is_selected = false
        selected_unit.queue_redraw()
    selected_unit = null
    if grid:
        grid.clear_highlights()

func show_move_highlights(unit: Node) -> void:
    if grid == null:
        return
    var tiles: Array[Vector2i] = []
    for x in range(grid.grid_size.x):
        for y in range(grid.grid_size.y):
            var tile = Vector2i(x, y)
            if unit.can_move_to(tile, grid) and get_unit_at(tile) == null:
                tiles.append(tile)
    grid.set_highlights(tiles)

func maybe_finish_player_turn() -> void:
    if check_victory():
        return
    for unit in get_team_units("player"):
        if not unit.has_acted:
            update_ui_message("Choose another unit, or finish the turn by moving/attacking with everyone.")
            return
    update_ui_message("Enemy turn incoming.")
    advance_turn()

func reset_team_actions(team_name: String) -> void:
    for unit in get_team_units(team_name):
        unit.has_acted = false
        unit.queue_redraw()
