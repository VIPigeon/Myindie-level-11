class_name DragController

signal fuel_burned(value: int)
signal helper_burned(helper: Helper)
signal item_dropped
signal item_picked

var world_node: Node2D
var fuel_controller: FuelController
var fire: Fire
var enabled := true
var hovered_fuel: Fuel
var helpers: Array[Helper]
var start_z_index: int
var dragged_fuel: Fuel
var start_position: Vector2
var grab_offset: Vector2


func _init(world_node_: Node2D, fuel_controller_: FuelController, fire_: Fire) -> void:
	self.world_node = world_node_
	self.fuel_controller = fuel_controller_
	self.fire = fire_


func handle_input(event: InputEvent) -> void:
	if !enabled:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_drag()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var position: Vector2 = world_node.get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			start_drag(position)
		elif dragged_fuel != null:
			move_drag(position)
			finish_drag()
	elif event is InputEventMouseMotion:
		var position: Vector2 = world_node.get_global_transform_with_canvas().affine_inverse() * event.position
		if dragged_fuel != null:
			move_drag(position)
		else:
			update_hover(position)


func start_drag(position: Vector2) -> void:
	if !enabled or dragged_fuel != null:
		return

	clear_hover()
	var candidates: Array[Fuel] = fuel_controller.fuels.duplicate()
	candidates.append_array(helpers)
	for i in range(candidates.size() - 1, -1, -1):
		var fuel := candidates[i]
		if !fuel.contains_point(position):
			continue

		var helper := fuel.reserved_by as Helper
		if helper != null:
			if helper.carrying:
				continue
			helper.reset_job()

		if fuel is Helper:
			fuel.reset_job()

		dragged_fuel = fuel
		start_z_index = fuel.z_index
		start_position = fuel.position
		grab_offset = fuel.position - position
		fuel.z_index = Config.dragged_z_index
		fuel.set_dragged(true)
		fire.show_contact(position)
		item_picked.emit()
		return


func move_drag(position: Vector2) -> void:
	dragged_fuel.position = position + grab_offset
	var over_fire := fire.contains_point(dragged_fuel.position)
	dragged_fuel.set_heat(over_fire)
	fire.set_highlighted(over_fire)
	fire.show_contact(position)


func finish_drag() -> void:
	if !fire.contains_point(dragged_fuel.position):
		drop_drag()
		return

	var fuel := release_drag()
	fire.feed(fuel.position)
	if fuel is Helper:
		helper_burned.emit(fuel)
	else:
		fuel_controller.consume_fuel(fuel)
		fuel_burned.emit(fuel.point_value)


func drop_drag() -> void:
	var fuel := release_drag()
	fuel.land()
	item_dropped.emit()


func cancel_drag() -> void:
	clear_hover()
	if dragged_fuel == null:
		return

	dragged_fuel.position = start_position
	release_drag()


func release_drag() -> Fuel:
	var fuel := dragged_fuel
	fuel.z_index = start_z_index
	fuel.set_dragged(false)
	dragged_fuel = null
	fire.set_highlighted(false)
	fire.clear_contact()
	return fuel


func update_hover(position: Vector2) -> void:
	var next: Fuel
	var candidates: Array[Fuel] = fuel_controller.fuels.duplicate()
	candidates.append_array(helpers)
	for index in range(candidates.size() - 1, -1, -1):
		if candidates[index].contains_point(position):
			next = candidates[index]
			break
	if next == hovered_fuel:
		return

	clear_hover()
	hovered_fuel = next
	if hovered_fuel != null:
		hovered_fuel.set_hovered(true)


func clear_hover() -> void:
	if is_instance_valid(hovered_fuel):
		hovered_fuel.set_hovered(false)
	hovered_fuel = null
