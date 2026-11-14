class_name FuelController

var world_node: Node2D
var fire: Fire
var fuels: Array[Fuel]
var spawn_rect: Rect2
var stage: int = 0
var burning_fuels: Array[Fuel]
var moon_remaining := true
var packs_remaining: int = 0
var stage_scale: float = 1.0
var car_scene := preload("res://game/car/car.tscn")
var fuel_scene := preload("res://game/fuel/fuel.tscn")


func _init(world_node_: Node2D, fire_: Fire) -> void:
	self.world_node = world_node_
	self.fire = fire_
	spawn_rect = Rect2(-Config.world_size * 0.5, Config.world_size).grow(-Config.spawn_padding)


func spawn_fuel() -> Fuel:
	if stage == GlobalConfig.Stage.PLANET and !moon_remaining:
		return null

	var fuel: Fuel = fuel_scene.instantiate()
	if stage == GlobalConfig.Stage.CAMP and packs_remaining > 0:
		fuel.kind = Fuel.Kind.PACK
	else:
		var kinds: PackedInt32Array = Config.stage_fuel_kinds[stage]
		fuel.kind = kinds[randi_range(0, kinds.size() - 1)]

	fuel.flight_direction = 1.0 if randf() > 0.5 else -1.0
	fuel.stage = stage
	fuel.scale = Vector2.ONE * stage_scale
	world_node.add_child(fuel)
	for i in range(Config.spawn_attempts):
		var position := Vector2(
			randf_range(spawn_rect.position.x, spawn_rect.end.x),
			randf_range(spawn_rect.position.y, spawn_rect.end.y),
		)
		if !can_spawn_at(position, fuel.bounds):
			continue

		fuel.position = position
		fuels.append(fuel)
		if fuel.kind == Fuel.Kind.MOON:
			moon_remaining = false
		elif fuel.kind == Fuel.Kind.PACK:
			packs_remaining -= 1
		return fuel
	fuel.queue_free()
	return null


func can_spawn_at(position: Vector2, bounds: Rect2) -> bool:
	if stage == GlobalConfig.Stage.SURFACE and position.y > 0.0:
		return false

	var road_top: float = Config.world_size.y * Config.road_top_ratio - Config.fuel_size.y
	if stage == GlobalConfig.Stage.HOUSE and position.y > road_top * stage_scale:
		return false

	var clearance: float = Config.fire_radius * fire.target_scale + Config.fire_clearance * stage_scale
	if position.distance_to(fire.position) < clearance:
		return false

	var rect := Rect2(position + bounds.position * stage_scale, bounds.size * stage_scale)
	var field := Rect2(-Config.world_size * stage_scale * 0.5, Config.world_size * stage_scale)
	if !field.encloses(rect):
		return false

	for fuel in fuels:
		if position.distance_to(fuel.position) < Config.fuel_spacing * stage_scale:
			return false

		var other := Rect2(fuel.position + fuel.bounds.position * stage_scale, fuel.bounds.size * stage_scale)
		if rect.intersects(other):
			return false

	return true


func remove_fuel(fuel: Fuel) -> void:
	fuels.erase(fuel)
	fuel.queue_free()


func set_stage(value: int, scale_: float) -> void:
	clear_burning()
	moon_remaining = true
	stage = value
	packs_remaining = Config.camp_initial_packs if stage == GlobalConfig.Stage.CAMP else 0
	stage_scale = scale_
	var size: Vector2 = Config.world_size * stage_scale
	spawn_rect = Rect2(-size * 0.5, size).grow(-Config.spawn_padding * stage_scale)
	for fuel in fuels:
		fuel.queue_free()
	fuels.clear()


func refill() -> void:
	while stationary_count() < Config.starting_items:
		if spawn_fuel() == null:
			break


func stationary_count() -> int:
	var count: int = 0
	for fuel in fuels:
		if !(fuel is Car):
			count += 1
	return count


func tick(delta: float) -> void:
	for fuel in fuels:
		fuel.tick_flight(delta)
	if stage != GlobalConfig.Stage.HOUSE:
		return

	var cars: int = 0
	for fuel in fuels:
		if fuel is Car:
			fuel.tick(delta)
			cars += 1
	if cars < Config.car_count:
		spawn_car(cars)


func spawn_car(index: int) -> Car:
	var car: Car = car_scene.instantiate()
	car.stage = stage
	car.scale = Vector2.ONE * stage_scale
	car.direction = 1.0 if index % 2 == 0 else -1.0
	car.road_half_width = Config.world_size.x * stage_scale * 0.5
	car.position = Vector2(
		-car.road_half_width + index * Config.car_spacing * stage_scale,
		Config.world_size.y * stage_scale * Config.road_lane_ratio,
	)
	world_node.add_child(car)
	fuels.append(car)
	return car


func consume_fuel(fuel: Fuel) -> void:
	if !fuels.has(fuel):
		return

	fuels.erase(fuel)
	fuel.burn(fire.position)
	burning_fuels.append(fuel)


func clear_burning() -> void:
	for fuel in burning_fuels:
		fuel.queue_free()
	burning_fuels.clear()


func tick_burning(delta: float) -> void:
	for fuel in burning_fuels.duplicate():
		if fuel.tick_burn(delta):
			burning_fuels.erase(fuel)
			fuel.queue_free()
