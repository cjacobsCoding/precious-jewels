extends Node2D

@export var tile_size: int = 64
@export var grid_width: int = 8
@export var grid_height: int = 6

var selected_unit: Node = null
var units: Array = []
var grid: Node = null

func _ready() -> void:
    grid = $Grid
    grid.setup(Vector2i(grid_width, grid_height), tile_size)
    spawn_units()
    update_unit_tiles()

func spawn_units() -> void:
    var player_unit = preload("res://scripts/Unit.gd").instantiate()
    player_unit.team = "player"
    player_unit.movement_range = 4
    add_child(player_unit)
    units.append(player_unit)
    player_unit.set_tile_position(grid, Vector2i(1, 1))

    var enemy_unit = preload("res://scripts/Unit.gd").instantiate()
    enemy_unit.team = "enemy"
    enemy_unit.movement_range = 3
    add_child(enemy_unit)
    units.append(enemy_unit)
    enemy_unit.set_tile_position(grid, Vector2i(5, 3))

func update_unit_tiles() -> void:
    for unit in units:
        unit.update_label()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var click_pos = event.position
        var cell = grid.world_to_grid(click_pos)
        if selected_unit:
            if selected_unit.can_move_to(cell, grid):
                selected_unit.set_tile_position(grid, cell)
                selected_unit = null
            else:
                selected_unit = null
        else:
            selected_unit = get_unit_at(cell)

func get_unit_at(tile: Vector2i) -> Node:
    for unit in units:
        if unit.tile_position == tile:
            return unit
    return null
