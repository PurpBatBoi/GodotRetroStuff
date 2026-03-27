# MIT License
# Copyright (c) 2019 Lupo Dharkael

class_name FpsLabel

extends CanvasLayer


enum Position {TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, NONE}

@export var position_enum: Position = Position.TOP_LEFT
@export var margin: int = 5

var label: Label


func _ready() -> void:
	label = Label.new()
	add_child(label)
	get_tree().root.size_changed.connect(update_position)
	update_position()


# pos should be of type Position
func set_position(pos: int) -> void:
	position_enum = pos
	update_position()


func update_position() -> void:
	var viewport_size: Vector2 = get_viewport().size
	var label_size: Vector2 = label.size
	
	match position_enum:
		Position.TOP_LEFT:
			label.position = Vector2(margin, margin)
		Position.BOTTOM_LEFT:
			label.position = Vector2(margin, viewport_size.y - margin - label_size.y)
		Position.TOP_RIGHT:
			label.position = Vector2(viewport_size.x - margin - label_size.x, margin)
		Position.BOTTOM_RIGHT:
			label.position = Vector2(viewport_size.x - margin - label_size.x, viewport_size.y - margin - label_size.y)


func _process(_delta: float) -> void:
	label.text = "fps: " + str(Engine.get_frames_per_second())
