extends Node2D
class_name Unit

@export var team: String = "player"
@export var movement_range: int = 4
var tile_position: Vector2i = Vector2i.ZERO

func set_tile_position(grid: Node, tile: Vector2i) -> void:
    if not grid.is_in_bounds(tile):
        push_error("Tile position out of bounds: %s" % tile)
        return
    tile_position = tile
    position = grid.grid_to_world(tile)

func can_move_to(target: Vector2i, grid: Node) -> bool:
    if not grid.is_in_bounds(target):
        return false
    var distance = abs(target.x - tile_position.x) + abs(target.y - tile_position.y)
    return distance <= movement_range

func update_label() -> void:
    pass
