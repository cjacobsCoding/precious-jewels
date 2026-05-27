extends Node2D
class_name Unit

@export var team: String = "player"
@export var movement_range: int = 4
@export var max_hp: int = 10
@export var attack: int = 3
var hp: int = 10
var tile_size: int = 64
var tile_position: Vector2i = Vector2i.ZERO
var is_selected: bool = false

func _ready() -> void:
    hp = max_hp
    queue_redraw()

func set_tile_position(grid: Node, tile: Vector2i) -> void:
    if not grid.is_in_bounds(tile):
        push_error("Tile position out of bounds: %s" % tile)
        return
    tile_position = tile
    tile_size = grid.tile_size
    position = grid.grid_to_world(tile)
    queue_redraw()

func can_move_to(target: Vector2i, grid: Node) -> bool:
    if not grid.is_in_bounds(target):
        return false
    var distance = abs(target.x - tile_position.x) + abs(target.y - tile_position.y)
    return distance <= movement_range

func can_attack(target: Node) -> bool:
    var distance = abs(target.tile_position.x - tile_position.x) + abs(target.tile_position.y - tile_position.y)
    return distance == 1

func attack_unit(target: Node) -> void:
    target.take_damage(attack)

func take_damage(amount: int) -> void:
    hp -= amount
    if hp < 0:
        hp = 0
    queue_redraw()

func is_alive() -> bool:
    return hp > 0

func update_label() -> void:
    queue_redraw()

func _draw() -> void:
    var color: Color
    if team == "player":
        color = Color(0.2, 0.6, 1.0)
    else:
        color = Color(1.0, 0.3, 0.3)
    draw_rect(Rect2(-tile_size * 0.35, -tile_size * 0.35, tile_size * 0.7, tile_size * 0.7), color)
    if is_selected:
        draw_rect(Rect2(-tile_size * 0.4, -tile_size * 0.4, tile_size * 0.8, tile_size * 0.8), Color(1, 1, 0, 0.25), false, 4)
