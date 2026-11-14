class_name Helper extends Fuel

const SPRITES := preload("res://art/dude.png")

var animation_frames: Array[AtlasTexture] = []
var animation_time: float = 0.0

var fuel_controller: FuelController
var fire: Fire
var target: Fuel
var carrying := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cell := Vector2i(SPRITES.get_height(), SPRITES.get_height())
	for index in SPRITES.get_width() / cell.x:
		var frame := AtlasTexture.new()
		frame.atlas = SPRITES
		frame.region = Rect2(Vector2(index * cell.x, 0), Vector2(cell))
		animation_frames.append(frame)
	art_texture = animation_frames[0]
	var size := Vector2(cell) * Config.world_pixel_size
	art_bounds = Rect2(-size * 0.5, size)
	bounds = art_bounds.grow(Config.fuel_hit_padding)
	setup_feedback()


func reset_job() -> void:
	if is_instance_valid(target) and target.reserved_by == self:
		target.reserved_by = null
	target = null
	carrying = false


func tick(delta: float) -> int:
	if dragged or burning:
		return 0

	update_animation(delta)
	if !is_instance_valid(target) or target.is_queued_for_deletion() or target.dragged or target.reserved_by != self:
		reset_job()
		target = find_target()
		if target == null:
			return 0

		target.reserved_by = self

	var destination := fire.position if carrying else target.position
	position = position.move_toward(destination, Config.helper_speed * scale.x * delta)
	if carrying:
		target.position = position + Vector2.UP * Config.helper_pickup_distance * scale.x
		if fire.contains_point(position):
			var value := target.point_value
			fuel_controller.consume_fuel(target)
			reset_job()
			fire.feed()
			return value
	elif position.distance_to(target.position) <= Config.helper_pickup_distance * scale.x:
		carrying = true
	return 0


func update_animation(delta: float) -> void:
	animation_time += delta
	var index := int(animation_time * Config.helper_animation_fps) % animation_frames.size()
	if art_texture != animation_frames[index]:
		art_texture = animation_frames[index]
		queue_redraw()


func find_target() -> Fuel:
	var nearest: Fuel
	var nearest_distance := INF
	for fuel in fuel_controller.fuels:
		if fuel is Car or fuel.is_flying() or fuel.dragged or fuel.reserved_by != null:
			continue

		var distance := position.distance_squared_to(fuel.position)
		if distance < nearest_distance:
			nearest = fuel
			nearest_distance = distance

	return nearest
