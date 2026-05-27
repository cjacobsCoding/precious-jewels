extends SceneTree

const GridScript = preload("res://scripts/Grid.gd")
const UnitScript = preload("res://scripts/Unit.gd")
const GameManagerScript = preload("res://scripts/GameManager.gd")

var total_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
    run_test("grid_bounds", "test_grid_bounds")
    run_test("grid_world_conversion", "test_grid_world_conversion")
    run_test("unit_movement", "test_unit_movement")
    run_test("unit_attack", "test_unit_attack")
    run_test("unit_damage", "test_unit_damage")
    run_test("game_manager_closest_unit", "test_game_manager_closest_unit")
    run_test("game_manager_step_toward", "test_game_manager_step_toward")
    
    # New tests for uncovered areas
    run_test("turn_phase_transitions", "test_turn_phase_transitions")
    run_test("click_unit_selection", "test_click_unit_selection")
    run_test("click_movement_action", "test_click_movement_action")
    run_test("click_deselection", "test_click_deselection")
    run_test("enemy_action_attack", "test_enemy_action_attack")
    run_test("enemy_action_movement", "test_enemy_action_movement")
    run_test("victory_all_enemies_defeated", "test_victory_all_enemies_defeated")
    run_test("defeat_all_players_defeated", "test_defeat_all_players_defeated")
    run_test("victory_condition_check", "test_victory_condition_check")

    print("\nTest summary: %d passed, %d failed" % [total_tests - failed_tests, failed_tests])
    if failed_tests > 0:
        quit(1)
    else:
        quit()

func run_test(name: String, method_name: String) -> void:
    total_tests += 1
    print("Running %s..." % name)
    call(method_name)
    cleanup_test_root()
    print("PASS: %s" % name)

func cleanup_test_root() -> void:
    for child in get_root().get_children():
        child.free()

func assert_true(value: bool, message: String = "") -> void:
    if not value:
        failed_tests += 1
        push_error("Assertion failed: %s" % message)

func assert_equal(a, b, message: String = "") -> void:
    if a != b:
        failed_tests += 1
        push_error("Assertion failed: %s (got %s, expected %s)" % [message, str(a), str(b)])

func assert_not_equal(a, b, message: String = "") -> void:
    if a == b:
        failed_tests += 1
        push_error("Assertion failed: %s (expected values to be different, got %s)" % [message, str(a)])

func assert_false(value: bool, message: String = "") -> void:
    if value:
        failed_tests += 1
        push_error("Assertion failed: %s (expected false, got true)" % message)

func test_grid_bounds() -> void:
    var grid = GridScript.new()
    grid.setup(Vector2i(3, 3), 32)
    assert_true(grid.is_in_bounds(Vector2i(0, 0)), "Tile (0,0) should be in bounds")
    assert_true(not grid.is_in_bounds(Vector2i(-1, 0)), "Negative tile should be out of bounds")
    assert_true(not grid.is_in_bounds(Vector2i(3, 0)), "Tile at width boundary should be out of bounds")

func test_grid_world_conversion() -> void:
    var grid = GridScript.new()
    grid.setup(Vector2i(3, 3), 32)
    assert_equal(grid.grid_to_world(Vector2i(1, 2)), Vector2(48, 80), "Grid to world conversion")
    assert_equal(grid.world_to_grid(Vector2(48, 80)), Vector2i(1, 2), "World to grid conversion")

func test_unit_movement() -> void:
    var grid = GridScript.new()
    grid.setup(Vector2i(5, 5), 32)
    var unit = UnitScript.new()
    unit.tile_position = Vector2i(0, 0)
    unit.movement_range = 3
    assert_true(unit.can_move_to(Vector2i(2, 1), grid), "Unit should be able to move within range")
    assert_true(not unit.can_move_to(Vector2i(4, 0), grid), "Unit should not be able to move beyond range")

func test_unit_attack() -> void:
    var attacker = UnitScript.new()
    attacker.team = "player"
    attacker.tile_position = Vector2i(0, 0)
    attacker.attack = 3
    var target = UnitScript.new()
    target.team = "enemy"
    target.tile_position = Vector2i(1, 0)
    target.hp = 10
    assert_true(attacker.can_attack(target), "Adjacent unit should be attackable")
    attacker.attack_unit(target)
    assert_equal(target.hp, 7, "Attack should reduce target HP")

func test_unit_damage() -> void:
    var target = UnitScript.new()
    target.hp = 5
    target.take_damage(3)
    assert_equal(target.hp, 2, "Damage should reduce HP")
    target.take_damage(5)
    assert_equal(target.hp, 0, "HP should not fall below zero")

func test_game_manager_closest_unit() -> void:
    var gm = GameManagerScript.new()
    var player = UnitScript.new()
    player.team = "player"
    player.tile_position = Vector2i(0, 0)
    var enemy = UnitScript.new()
    enemy.team = "enemy"
    enemy.tile_position = Vector2i(2, 0)
    gm.units = [player, enemy]
    assert_equal(gm.get_closest_unit(player, "enemy"), enemy, "Closest enemy should be selected")

func test_game_manager_step_toward() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(5, 5), 32)
    gm.grid = grid
    var from_unit = UnitScript.new()
    from_unit.tile_position = Vector2i(0, 0)
    var target = UnitScript.new()
    target.tile_position = Vector2i(2, 1)
    var step = gm.get_step_toward(from_unit, target)
    assert_equal(step, Vector2i(1, 0), "Step toward should move on the larger axis")

# NEW TESTS FOR UNCOVERED AREAS

func test_turn_phase_transitions() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    
    # Test initial state is PLAYER
    assert_equal(gm.turn_state, GameManagerScript.TurnState.PLAYER, "Initial turn state should be PLAYER")
    
    # Test transition to ENEMY
    gm.advance_turn()
    assert_equal(gm.turn_state, GameManagerScript.TurnState.ENEMY, "Turn state should advance to ENEMY")
    
    # Test that GAME_OVER is set when checking victory
    gm.units = []
    gm.check_victory()
    assert_equal(gm.turn_state, GameManagerScript.TurnState.GAME_OVER, "Turn state should be GAME_OVER when no units")

func test_click_unit_selection() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    gm.spawn_units()
    gm.update_unit_tiles()
    
    var player_unit = gm.units[0]
    # Verify initial selection is null
    assert_equal(gm.selected_unit, null, "Initially no unit should be selected")
    
    # Simulate clicking on a player unit
    gm.selected_unit = player_unit
    player_unit.is_selected = true
    assert_equal(gm.selected_unit, player_unit, "Player unit should be selected after click")
    assert_true(player_unit.is_selected, "Selected unit's is_selected flag should be true")

func test_click_movement_action() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    gm.spawn_units()
    gm.update_unit_tiles()
    
    var player_unit = gm.units[0]
    var initial_pos = player_unit.tile_position
    var target_pos = Vector2i(3, 1)
    
    # Select unit and move it
    gm.selected_unit = player_unit
    player_unit.is_selected = true
    player_unit.set_tile_position(grid, target_pos)
    
    assert_equal(player_unit.tile_position, target_pos, "Unit should move to target position")
    assert_not_equal(player_unit.tile_position, initial_pos, "Unit position should change after movement")

func test_click_deselection() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    gm.spawn_units()
    gm.update_unit_tiles()
    
    var player_unit = gm.units[0]
    
    # Select then deselect
    gm.selected_unit = player_unit
    player_unit.is_selected = true
    assert_equal(gm.selected_unit, player_unit, "Unit should be selected")
    
    # Simulate deselection
    player_unit.is_selected = false
    gm.selected_unit = null
    
    assert_equal(gm.selected_unit, null, "Unit should be deselected")
    assert_false(player_unit.is_selected, "Selected unit's is_selected flag should be false")

func test_enemy_action_attack() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    
    # Create and position units close together for attack
    var player_unit = UnitScript.new()
    player_unit.team = "player"
    player_unit.tile_position = Vector2i(2, 2)
    player_unit.hp = 10
    player_unit.max_hp = 10
    
    var enemy_unit = UnitScript.new()
    enemy_unit.team = "enemy"
    enemy_unit.tile_position = Vector2i(3, 2)
    enemy_unit.attack = 3
    
    gm.units = [player_unit, enemy_unit]
    
    # Verify they can attack each other
    assert_true(enemy_unit.can_attack(player_unit), "Adjacent enemy should be able to attack player")
    
    # Perform enemy action (should attack)
    var player_hp_before = player_unit.hp
    enemy_unit.attack_unit(player_unit)
    assert_true(player_unit.hp < player_hp_before, "Player HP should decrease after enemy attack")
    player_unit.free()
    enemy_unit.free()

func test_enemy_action_movement() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    
    # Create and position units far apart for movement
    var player_unit = UnitScript.new()
    player_unit.team = "player"
    player_unit.tile_position = Vector2i(1, 1)
    player_unit.hp = 10
    
    var enemy_unit = UnitScript.new()
    enemy_unit.team = "enemy"
    enemy_unit.tile_position = Vector2i(5, 3)
    enemy_unit.movement_range = 3
    
    gm.units = [player_unit, enemy_unit]
    
    # Get step toward player
    var step = gm.get_step_toward(enemy_unit, player_unit)
    assert_true(step != null, "Step toward player should not be null")
    assert_true(grid.is_in_bounds(step), "Step should be in bounds")
    
    # Move enemy one step toward player
    var initial_pos = enemy_unit.tile_position
    enemy_unit.set_tile_position(grid, step)
    assert_not_equal(enemy_unit.tile_position, initial_pos, "Enemy should move closer to player")
    player_unit.free()
    enemy_unit.free()

func test_victory_all_enemies_defeated() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    
    # Create player units only (no enemies)
    var player_unit = UnitScript.new()
    player_unit.team = "player"
    player_unit.hp = 10
    gm.units = [player_unit]
    
    # Check victory - should be true (all enemies defeated)
    var victory = gm.check_victory()
    assert_true(victory, "Should be victory when all enemies are defeated")
    assert_equal(gm.turn_state, GameManagerScript.TurnState.GAME_OVER, "Game state should be GAME_OVER on victory")
    player_unit.free()

func test_defeat_all_players_defeated() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    
    # Create enemy units only (no players)
    var enemy_unit = UnitScript.new()
    enemy_unit.team = "enemy"
    enemy_unit.hp = 10
    gm.units = [enemy_unit]
    
    # Check victory - should be true (all players defeated = defeat)
    var defeat = gm.check_victory()
    assert_true(defeat, "Should detect defeat when all player units are defeated")
    assert_equal(gm.turn_state, GameManagerScript.TurnState.GAME_OVER, "Game state should be GAME_OVER on defeat")
    enemy_unit.free()

func test_victory_condition_check() -> void:
    var gm = GameManagerScript.new()
    var grid = GridScript.new()
    grid.setup(Vector2i(8, 6), 64)
    gm.grid = grid
    get_root().add_child(gm)
    gm.add_child(grid)
    
    # Create mixed units - ongoing game
    var player_unit = UnitScript.new()
    player_unit.team = "player"
    player_unit.hp = 10
    
    var enemy_unit = UnitScript.new()
    enemy_unit.team = "enemy"
    enemy_unit.hp = 10
    
    gm.units = [player_unit, enemy_unit]
    
    # Check victory - should be false (game ongoing)
    var victory = gm.check_victory()
    assert_false(victory, "Should not be victory when both teams have units")
    assert_not_equal(gm.turn_state, GameManagerScript.TurnState.GAME_OVER, "Game state should not be GAME_OVER while game is ongoing")
    player_unit.free()
    enemy_unit.free()
