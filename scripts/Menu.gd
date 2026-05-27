extends Control

func _ready() -> void:
    $VBox/Play.pressed.connect(_on_Play_pressed)
    $VBox/Editor.pressed.connect(_on_Editor_pressed)
    $VBox/Exit.pressed.connect(_on_Exit_pressed)

func _on_Play_pressed() -> void:
    get_tree().change_scene("res://scenes/Main.tscn")

func _on_Editor_pressed() -> void:
    get_tree().change_scene("res://scenes/Editor.tscn")

func _on_Exit_pressed() -> void:
    get_tree().quit()
