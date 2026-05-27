extends Node2D

enum TurnState { PLAYER, ENEMY, GAME_OVER }

@export var tile_size: int = 64
@export var grid_width: int = 8
@export var grid_height: int = 6

var selected_unit: Node = null
var pending_attack_target: Node = null
var active_unit_origin: Vector2i = Vector2i.ZERO
var active_unit_has_origin: bool = false
var units: Array = []
var grid: Node = null
var turn_state: TurnState = TurnState.PLAYER
var turn_count: int = 1
var message_token: int = 0

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
    player_unit.defense = 1
    add_child(player_unit)
    units.append(player_unit)
    player_unit.set_tile_position(grid, Vector2i(1, 1))

    var player_unit_2 = preload("res://scripts/Unit.gd").new()
    player_unit_2.team = "player"
    player_unit_2.movement_range = 3
    player_unit_2.max_hp = 10
    player_unit_2.hp = 10
    player_unit_2.attack = 5
    player_unit_2.defense = 0
    add_child(player_unit_2)
    units.append(player_unit_2)
    player_unit_2.set_tile_position(grid, Vector2i(1, 3))

    var enemy_unit = preload("res://scripts/Unit.gd").new()
    enemy_unit.team = "enemy"
    enemy_unit.movement_range = 3
    enemy_unit.max_hp = 10
    enemy_unit.hp = 10
    enemy_unit.attack = 3
    enemy_unit.defense = 1
    add_child(enemy_unit)
    units.append(enemy_unit)
    enemy_unit.set_tile_position(grid, Vector2i(5, 3))

    var enemy_unit_2 = preload("res://scripts/Unit.gd").new()
    enemy_unit_2.team = "enemy"
    enemy_unit_2.movement_range = 3
    enemy_unit_2.max_hp = 8
    enemy_unit_2.hp = 8
    enemy_unit_2.attack = 4
    enemy_unit_2.defense = 0
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
    if event.button_index == MOUSE_BUTTON_RIGHT and pending_attack_target:
        pending_attack_target = null
        update_status_for_unit(selected_unit)
        update_ui_message(get_active_unit_prompt())
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
            if selected_unit.has_moved:
                update_ui_message("Finish this unit first: attack, wait, or press U to undo.")
                return
            clear_selection()
            update_ui_message("Selection cleared.")
            return
        if clicked_unit and clicked_unit.team == "enemy":
            update_status_for_unit(clicked_unit)
            if selected_unit.can_attack(clicked_unit):
                if pending_attack_target != clicked_unit:
                    pending_attack_target = clicked_unit
                    show_attack_forecast(selected_unit, clicked_unit)
                    return
                var damage = selected_unit.attack_unit(clicked_unit)
                pending_attack_target = null
                finish_player_action(selected_unit, "Player dealt %d damage." % damage)
                if not clicked_unit.is_alive():
                    remove_unit(clicked_unit)
                    update_ui_message("Enemy defeated.")
                if not check_victory():
                    maybe_finish_player_turn()
                return
            if grid.attack_highlighted_tiles.has(cell):
                update_ui_message("Move next to that enemy, then attack.")
            else:
                update_ui_message("Enemy is out of this unit's threat range. Stats shown below.")
            return
        if selected_unit.can_move_to(cell, grid) and clicked_unit == null:
            if not active_unit_has_origin:
                active_unit_origin = selected_unit.tile_position
                active_unit_has_origin = true
            selected_unit.set_tile_position(grid, cell)
            selected_unit.has_moved = true
            pending_attack_target = null
            selected_unit.queue_redraw()
            show_move_highlights(selected_unit)
            update_status_for_unit(selected_unit)
            update_ui_message("Unit moved. Attack, wait, or press U to undo.")
            return
        if clicked_unit and clicked_unit.team == "player" and not clicked_unit.has_acted:
            if selected_unit.has_moved:
                update_ui_message("Finish this unit first: attack, wait, or press U to undo.")
                return
            selected_unit.is_selected = false
            selected_unit.queue_redraw()
            clicked_unit.is_selected = true
            selected_unit = clicked_unit
            active_unit_origin = selected_unit.tile_position
            active_unit_has_origin = false
            pending_attack_target = null
            selected_unit.queue_redraw()
            show_move_highlights(selected_unit)
            update_status_for_unit(selected_unit)
            update_ui_message("Selected another player unit.")
            return
        update_ui_message("Invalid action. Choose a highlighted tile or adjacent enemy.")
        return

    if clicked_unit and clicked_unit.team == "player" and not clicked_unit.has_acted:
        selected_unit = clicked_unit
        active_unit_origin = selected_unit.tile_position
        active_unit_has_origin = false
        selected_unit.is_selected = true
        selected_unit.queue_redraw()
        show_move_highlights(selected_unit)
        update_status_for_unit(selected_unit)
        update_ui_message("Selected player unit. Move to a highlight or attack an adjacent enemy.")
    elif clicked_unit and clicked_unit.team == "enemy":
        update_status_for_unit(clicked_unit)
        update_ui_message("Enemy: HP %d/%d, ATK %d, DEF %d." % [clicked_unit.hp, clicked_unit.max_hp, clicked_unit.attack, clicked_unit.defense])
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
        var damage = enemy.attack_unit(target)
        enemy.has_moved = true
        enemy.has_acted = true
        update_unit_tiles()
        if not target.is_alive():
            remove_unit(target)
            update_unit_tiles()
        update_ui_message("Enemy dealt %d damage!" % damage)
        return

    var destination = get_step_toward(enemy, target)
    if destination != null and get_unit_at(destination) == null:
        enemy.set_tile_position(grid, destination)
        enemy.has_moved = true
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
    update_status()

func update_ui_message(message: String) -> void:
    message_token += 1
    if has_node("UI/MessageLabel"):
        $UI/MessageLabel.text = message

func update_ui_message_later(message: String, delay: float = 1.1) -> void:
    message_token += 1
    var token = message_token
    await get_tree().create_timer(delay).timeout
    if token == message_token and has_node("UI/MessageLabel"):
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
    unit.has_moved = true
    unit.has_acted = true
    active_unit_has_origin = false
    clear_selection()
    update_unit_tiles()
    update_ui_message(message)

func clear_selection() -> void:
    if selected_unit:
        selected_unit.is_selected = false
        selected_unit.queue_redraw()
    selected_unit = null
    pending_attack_target = null
    active_unit_has_origin = false
    if grid:
        grid.clear_highlights()
    update_status()

func show_move_highlights(unit: Node) -> void:
    if grid == null:
        return
    var move_tiles: Array[Vector2i] = []
    var attack_tiles: Array[Vector2i] = []
    var attack_sources: Array[Vector2i] = [unit.tile_position]
    for x in range(grid.grid_size.x):
        for y in range(grid.grid_size.y):
            var tile = Vector2i(x, y)
            if unit.can_move_to(tile, grid) and get_unit_at(tile) == null:
                move_tiles.append(tile)
                attack_sources.append(tile)

    for source in attack_sources:
        for tile in get_adjacent_tiles(source):
            if grid.is_in_bounds(tile) and not move_tiles.has(tile) and not attack_tiles.has(tile):
                attack_tiles.append(tile)
    grid.set_highlights(move_tiles, attack_tiles)

func can_attack_tile(unit: Node, tile: Vector2i) -> bool:
    if unit.has_acted or not grid.is_in_bounds(tile):
        return false
    var distance = abs(tile.x - unit.tile_position.x) + abs(tile.y - unit.tile_position.y)
    return distance == 1

func get_adjacent_tiles(tile: Vector2i) -> Array[Vector2i]:
    return [
        tile + Vector2i(1, 0),
        tile + Vector2i(-1, 0),
        tile + Vector2i(0, 1),
        tile + Vector2i(0, -1),
    ]

func maybe_finish_player_turn() -> void:
    if check_victory():
        return
    for unit in get_team_units("player"):
        if not unit.has_acted:
            update_ui_message_later("Choose another unit, or finish the turn by moving/attacking with everyone.")
            return
    advance_turn_later()

func advance_turn_later(delay: float = 1.1) -> void:
    var token = message_token
    await get_tree().create_timer(delay).timeout
    if token == message_token and turn_state == TurnState.PLAYER:
        advance_turn()

func reset_team_actions(team_name: String) -> void:
    for unit in get_team_units(team_name):
        unit.has_moved = false
        unit.has_acted = false
        unit.queue_redraw()

func update_status() -> void:
    if has_node("UI/StatusLabel"):
        if selected_unit:
            update_status_for_unit(selected_unit)
        else:
            $UI/StatusLabel.text = "No unit selected"

func update_status_for_unit(unit: Node) -> void:
    if not has_node("UI/StatusLabel"):
        return
    var team_name = "Player" if unit.team == "player" else "Enemy"
    $UI/StatusLabel.text = "%s HP %d/%d | ATK %d | DEF %d" % [team_name, unit.hp, unit.max_hp, unit.attack, unit.defense]

func show_attack_forecast(attacker: Node, target: Node) -> void:
    var damage = attacker.get_damage_against(target)
    var remaining_hp = max(0, target.hp - damage)
    if has_node("UI/StatusLabel"):
        $UI/StatusLabel.text = "Forecast: deal %d damage | Enemy HP %d -> %d" % [damage, target.hp, remaining_hp]
    update_ui_message("Attack forecast shown. Click the enemy again to confirm.")

func _unhandled_key_input(event: InputEvent) -> void:
    if turn_state != TurnState.PLAYER or not event.pressed:
        return
    if event is InputEventKey and event.keycode == KEY_U:
        undo_active_unit_move()

func undo_active_unit_move() -> void:
    if selected_unit == null or not selected_unit.has_moved or not active_unit_has_origin:
        update_ui_message("No move to undo.")
        return
    selected_unit.set_tile_position(grid, active_unit_origin)
    selected_unit.has_moved = false
    pending_attack_target = null
    active_unit_has_origin = false
    show_move_highlights(selected_unit)
    update_status_for_unit(selected_unit)
    update_ui_message("Move undone. Choose a move, switch units, or wait.")

func get_active_unit_prompt() -> String:
    if selected_unit and selected_unit.has_moved:
        return "Choose a target, right-click to wait, or press U to undo."
    return "Choose a target or right-click to wait."
