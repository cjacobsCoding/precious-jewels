extends Control

func _ready() -> void:
    $VBox/Back.pressed.connect(_on_Back_pressed)

func _on_Back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/Menu.tscn")
