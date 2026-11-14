class_name StageProgress extends Control

@export var stage_icons: Array[Texture2D] = [null, null, null, null, null]
@export var reached_icons: Array[Texture2D] = [null, null, null, null, null]
@export var tint_icons := true
@export var marker_size := Vector2(24.0, 24.0)
@export var marker_spacing: float = 38.0
@export var line_width: float = 2.0
@export var visible_stages: int = 5

var markers: Array[TextureRect]
var reached_stage: int = 0
var default_icon := preload("res://game/ui/stage_progress/circle.svg")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in visible_stages:
		var marker := TextureRect.new()
		marker.position = Vector2(index * marker_spacing, 0)
		marker.size = marker_size
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)
		markers.append(marker)
	show_progress(0)


func show_progress(highest_stage: int) -> void:
	reached_stage = clampi(highest_stage, 0, visible_stages - 1)
	for index in markers.size():
		var reached := index <= reached_stage
		var marker := markers[index]
		marker.texture = get_icon(index, reached)
		marker.modulate = Color.WHITE
		if tint_icons:
			marker.modulate = Config.palette[6] if reached else Config.palette[2]

	queue_redraw()


func _draw() -> void:
	var start := marker_size * 0.5
	draw_line(start, start + Vector2((visible_stages - 1) * marker_spacing, 0), Config.palette[2], line_width)
	if reached_stage > 0:
		draw_line(start, start + Vector2(reached_stage * marker_spacing, 0), Config.palette[5], line_width)


func get_icon(index: int, reached: bool) -> Texture2D:
	if reached and index < reached_icons.size() and reached_icons[index] != null:
		return reached_icons[index]
	if index < stage_icons.size() and stage_icons[index] != null:
		return stage_icons[index]

	return default_icon
