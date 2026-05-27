extends Node

const GridScript = preload("res://scripts/Grid.gd")
const UnitScript = preload("res://scripts/Unit.gd")
const GameManagerScript = preload("res://scripts/GameManager.gd")

var total_tests: int = 0
var failed_tests: int = 0

func _ready() -> void:
    run_test("grid_bounds", "test_grid_bounds")
    run_test("grid_world_conversion", "test_grid_world_conversion")
    run_test("unit_movement", "test_unit_movement")
    run_test("unit_attack", "test_unit_attack")
    run_test("unit_damage", "test_unit_damage")
    run_test("game_manager_closest_unit", "test_game_manager_closest_unit")
    run_test("game_manager_step_toward", "test_game_manager_step_toward")

    print("\nTest summary: %d passed, %d failed" % [total_tests - failed_tests, failed_tests])
    if failed_tests > 0:
        get_tree().quit(1)
    else:
        get_tree().quit()

func run_test(name: String, method_name: String) -> void:
    total_tests += 1
    print("Running %s..." % name)
    var result = true
    var message = ""
    try:
        call(method_name)
    catch err:
        result = false
        message = err
    if result:
        print("PASS: %s" % name)
    else:
        failed_tests += 1
        print("FAIL: %s - %s" % [name, message])

func assert_true(value: bool, message: String = "") -> void:
    if not value:
        failed_tests += 1
        push_error("Assertion failed: %s" % message)

func assert_equal(a, b, message: String = "") -> void:
    if a != b:
        failed_tests += 1
        push_error("Assertion failed: %s (got %s, expected %s)" % [message, str(a), str(b)])

func test_grid_bounds() -> void:
    var grid = GridScript.instantiate()
    grid.setup(Vector2i(3, 3), 32)
    assert_true(grid.is_in_bounds(Vector2i(0, 0)), "Tile (0,0) should be in bounds")
    assert_true(not grid.is_in_bounds(Vector2i(-1, 0)), "Negative tile should be out of bounds")
    assert_true(not grid.is_in_bounds(Vector2i(3, 0)), "Tile at width boundary should be out of bounds")

func test_grid_world_conversion() -> void:
    var grid = GridScript.instantiate()
    grid.setup(Vector2i(3, 3), 32)
    assert_equal(grid.grid_to_world(Vector2i(1, 2)), Vector2(48, 80), "Grid to world conversion")
    assert_equal(grid.world_to_grid(Vector2(48, 80)), Vector2i(1, 2), "World to grid conversion")

func test_unit_movement() -> void:
    var grid = GridScript.instantiate()
    grid.setup(Vector2i(5, 5), 32)
    var unit = UnitScript.instantiate()
    unit.tile_position = Vector2i(0, 0)
    unit.movement_range = 3
    assert_true(unit.can_move_to(Vector2i(2, 1), grid), "Unit should be able to move within range")
    assert_true(not unit.can_move_to(Vector2i(4, 0), grid), "Unit should not be able to move beyond range")

func test_unit_attack() -> void:
    var attacker = UnitScript.instantiate()
    attacker.tile_position = Vector2i(0, 0)
    attacker.attack = 3
    var target = UnitScript.instantiate()
    target.tile_position = Vector2i(1, 0)
    target.hp = 10
    assert_true(attacker.can_attack(target), "Adjacent unit should be attackable")
    attacker.attack_unit(target)
    assert_equal(target.hp, 7, "Attack should reduce target HP")

func test_unit_damage() -> void:
    var target = UnitScript.instantiate()
    target.hp = 5
    target.take_damage(3)
    assert_equal(target.hp, 2, "Damage should reduce HP")
    target.take_damage(5)
    assert_equal(target.hp, 0, "HP should not fall below zero")

func test_game_manager_closest_unit() -> void:
    var gm = GameManagerScript.instantiate()
    var player = UnitScript.instantiate()
    player.team = "player"
    player.tile_position = Vector2i(0, 0)
    var enemy = UnitScript.instantiate()
    enemy.team = "enemy"
    enemy.tile_position = Vector2i(2, 0)
    gm.units = [player, enemy]
    assert_equal(gm.get_closest_unit(player, "enemy"), enemy, "Closest enemy should be selected")

func test_game_manager_step_toward() -> void:
    var gm = GameManagerScript.instantiate()
    var grid = GridScript.instantiate()
    grid.setup(Vector2i(5, 5), 32)
    gm.grid = grid
    var from_unit = UnitScript.instantiate()
    from_unit.tile_position = Vector2i(0, 0)
    var target = UnitScript.instantiate()
    target.tile_position = Vector2i(2, 1)
    var step = gm.get_step_toward(from_unit, target)
    assert_equal(step, Vector2i(1, 0), "Step toward should move on the larger axis")
