extends Node2D

var grid_size: Vector2i = Vector2i.ZERO
var tile_size: int = 64

func setup(grid_size_in: Vector2i, tile_size_in: int) -> void:
    grid_size = grid_size_in
    tile_size = tile_size_in

func grid_to_world(tile: Vector2i) -> Vector2:
    return Vector2(tile.x * tile_size + tile_size / 2, tile.y * tile_size + tile_size / 2)

func world_to_grid(world_pos: Vector2) -> Vector2i:
    return Vector2i(floor(world_pos.x / tile_size), floor(world_pos.y / tile_size))

func is_in_bounds(tile: Vector2i) -> bool:
    return tile.x >= 0 and tile.y >= 0 and tile.x < grid_size.x and tile.y < grid_size.y
