extends Node2D
class_name Unit

@export var team: String = "player"
@export var movement_range: int = 4
@export var max_hp: int = 10
@export var attack: int = 3
@export var defense: int = 1
var hp: int = 10
var tile_size: int = 64
var tile_position: Vector2i = Vector2i.ZERO
var is_selected: bool = false
var has_moved: bool = false
var has_acted: bool = false

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
    if has_moved or has_acted:
        return false
    if not grid.is_in_bounds(target):
        return false
    var distance = abs(target.x - tile_position.x) + abs(target.y - tile_position.y)
    return distance <= movement_range

func can_attack(target: Node) -> bool:
    if has_acted or target == null or target.team == team:
        return false
    var distance = abs(target.tile_position.x - tile_position.x) + abs(target.tile_position.y - tile_position.y)
    return distance == 1

func get_damage_against(target: Node) -> int:
    return max(1, attack - target.defense)

func attack_unit(target: Node) -> int:
    var damage = get_damage_against(target)
    target.take_damage(damage)
    return damage

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
    if has_acted:
        color = color.darkened(0.45)

    var body_rect = Rect2(-tile_size * 0.35, -tile_size * 0.35, tile_size * 0.7, tile_size * 0.7)
    draw_rect(body_rect, color)
    draw_rect(body_rect, Color(0.04, 0.05, 0.06), false, 2)
    if is_selected:
        draw_rect(Rect2(-tile_size * 0.4, -tile_size * 0.4, tile_size * 0.8, tile_size * 0.8), Color(1, 1, 0, 0.25), false, 4)

    var hp_ratio = float(hp) / float(max_hp)
    var bar_width = tile_size * 0.7
    var bar_bg = Rect2(-bar_width / 2, tile_size * 0.26, bar_width, 6)
    draw_rect(bar_bg, Color(0.02, 0.02, 0.02))
    draw_rect(Rect2(bar_bg.position, Vector2(bar_width * hp_ratio, bar_bg.size.y)), Color(0.2, 0.85, 0.35))
