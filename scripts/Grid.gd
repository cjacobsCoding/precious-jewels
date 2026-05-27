extends Node2D

var grid_size: Vector2i = Vector2i.ZERO
var tile_size: int = 64
var move_highlighted_tiles: Array[Vector2i] = []
var attack_highlighted_tiles: Array[Vector2i] = []

func setup(grid_size_in: Vector2i, tile_size_in: int) -> void:
    grid_size = grid_size_in
    tile_size = tile_size_in
    queue_redraw()

func grid_to_world(tile: Vector2i) -> Vector2:
    return Vector2(tile.x * tile_size + tile_size / 2, tile.y * tile_size + tile_size / 2)

func world_to_grid(world_pos: Vector2) -> Vector2i:
    return Vector2i(floor(world_pos.x / tile_size), floor(world_pos.y / tile_size))

func is_in_bounds(tile: Vector2i) -> bool:
    return tile.x >= 0 and tile.y >= 0 and tile.x < grid_size.x and tile.y < grid_size.y

func set_highlights(move_tiles: Array[Vector2i], attack_tiles: Array[Vector2i] = []) -> void:
    move_highlighted_tiles = move_tiles
    attack_highlighted_tiles = attack_tiles
    queue_redraw()

func clear_highlights() -> void:
    move_highlighted_tiles.clear()
    attack_highlighted_tiles.clear()
    queue_redraw()

func _draw() -> void:
    var board_rect = Rect2(Vector2.ZERO, Vector2(grid_size.x * tile_size, grid_size.y * tile_size))
    draw_rect(board_rect, Color(0.08, 0.1, 0.12))

    for tile in move_highlighted_tiles:
        var highlight_rect = Rect2(Vector2(tile.x * tile_size, tile.y * tile_size), Vector2(tile_size, tile_size))
        draw_rect(highlight_rect.grow(-3), Color(0.9, 0.82, 0.22, 0.32))

    for tile in attack_highlighted_tiles:
        var attack_rect = Rect2(Vector2(tile.x * tile_size, tile.y * tile_size), Vector2(tile_size, tile_size))
        draw_rect(attack_rect.grow(-3), Color(1.0, 0.18, 0.12, 0.28))

    for x in range(grid_size.x):
        for y in range(grid_size.y):
            var rect = Rect2(Vector2(x * tile_size, y * tile_size), Vector2(tile_size, tile_size))
            var fill = Color(0.16, 0.19, 0.22) if (x + y) % 2 == 0 else Color(0.13, 0.16, 0.19)
            draw_rect(rect.grow(-1), fill)
            if move_highlighted_tiles.has(Vector2i(x, y)):
                draw_rect(rect.grow(-5), Color(0.96, 0.82, 0.22, 0.34))
            if attack_highlighted_tiles.has(Vector2i(x, y)):
                draw_rect(rect.grow(-8), Color(1.0, 0.18, 0.12, 0.38))
            draw_rect(rect, Color(0.31, 0.34, 0.38), false, 1)
