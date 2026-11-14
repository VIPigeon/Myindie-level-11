extends Node2D


func _draw() -> void:
	var size: Vector2 = Config.world_size
	var top: float = size.y * Config.road_top_ratio
	draw_rect(Rect2(-size.x * 0.5, top, size.x, size.y * 0.5 - top), Config.palette[1])
	for i in range(12):
		var x: float = -size.x * 0.5 + i * size.x / 12.0
		draw_rect(Rect2(x, size.y * Config.road_lane_ratio, 28, 3), Config.palette[3])
