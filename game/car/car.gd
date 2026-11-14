class_name Car extends Fuel

var direction: float = 1.0
var road_half_width: float


func _ready() -> void:
	super._ready()
	bounds = Rect2(-Config.car_size * 0.5, Config.car_size)
	point_value = Config.car_points
	label.hide()


func tick(delta: float) -> void:
	if dragged:
		return

	position.x += direction * Config.car_speed * scale.x * delta
	var edge := road_half_width + bounds.size.x * scale.x
	if position.x > edge:
		position.x = -edge
	elif position.x < -edge:
		position.x = edge


func _draw() -> void:
	draw_set_transform(visual_offset + Vector2(0, landing_offset), visual_angle, Vector2.ONE * visual_scale)
	draw_rect(bounds, Config.palette[5] if !dragged else Config.palette[6])
	draw_rect(Rect2(bounds.position + Vector2(18, 5), Vector2(38, 21)), Config.palette[2])
	for x in [-25.0, 25.0]:
		draw_rect(Rect2(Vector2(x - 7, -23), Vector2(14, 7)), Config.palette[0])
		draw_rect(Rect2(Vector2(x - 7, 16), Vector2(14, 7)), Config.palette[0])
	draw_rect(Rect2(Vector2(34 * direction - 3, -12), Vector2(6, 24)), Config.palette[7])
