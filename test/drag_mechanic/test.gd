extends Node

@onready var root := get_tree().root

var main: Main
var failures: int


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	seed(12345)
	var config := root.get_node("Config")
	config.stage_upgrade_costs[0] = 10000
	main = load("res://main/main.tscn").instantiate()
	root.add_child(main)
	await get_tree().process_frame
	var gameplay := main.gameplay
	var controller := gameplay.drag_controller
	check(gameplay.fuel_controller.fuels.size() == config.starting_items, "Initial fuel count")
	for fuel in gameplay.fuel_controller.fuels:
		check(!gameplay.fire.contains_point(fuel.position), "Fuel spawns outside fire")

	var fuel := gameplay.fuel_controller.fuels[0]
	var origin := fuel.position
	var offset := Vector2(12.0, 8.0)
	click(origin + offset, true)
	motion(Vector2(140.0, 140.0))
	check(fuel.position.is_equal_approx(Vector2(140.0, 140.0) - offset), "Grab offset preserved")
	click(Vector2(140.0, 140.0), false)
	check(fuel.position.is_equal_approx(Vector2(140.0, 140.0) - offset), "Отпущенное топливо остаётся на новом месте")
	check(!fuel.dragged and controller.dragged_fuel == null, "Отпускание освобождает предмет")
	check(fuel.landing_tween != null, "Падение запускает анимацию")
	origin = fuel.position
	check(gameplay.score_controller.points.value == 0, "Invalid drop awards nothing")

	click(origin, true)
	motion(gameplay.fire.position)
	check(gameplay.fire.highlighted, "Fire previews valid drop")
	check(gameplay.score_controller.points.value == 0, "Hover alone awards nothing")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	main._input(cancel)
	check(fuel.position == origin and controller.dragged_fuel == null, "Escape cancels drag")

	click(origin, true)
	root.focus_exited.emit()
	check(controller.dragged_fuel == null, "Focus loss cancels drag")
	click(origin, true)
	root.mouse_exited.emit()
	check(controller.dragged_fuel == null, "Leaving window cancels drag")

	controller.start_drag(fuel.position)
	controller.move_drag(Vector2(70.0, 0.0))
	controller.finish_drag()
	var dropped := fuel
	var other := gameplay.fuel_controller.fuels[1]
	controller.start_drag(other.position)
	controller.move_drag(gameplay.fire.position)
	controller.finish_drag()
	check(is_instance_valid(dropped) and !dropped.is_queued_for_deletion(), "Кормление не удаляет лежащий рядом предмет")
	check(gameplay.fuel_controller.fuels.has(dropped) and !dropped.burning, "Лежащий рядом предмет остаётся доступным")
	check(dropped.position == Vector2(70.0, 0.0), "Кормление не сдвигает оставленный предмет")
	var expected_points: int = other.point_value
	for i in range(100):
		fuel = gameplay.fuel_controller.fuels[0]
		expected_points += fuel.point_value
		click(fuel.position, true)
		click(gameplay.fire.position, false)
		check(gameplay.score_controller.points.value == expected_points, "Valid drop awards fuel value once")
		check(gameplay.fuel_controller.fuels.size() == config.starting_items, "Consumed fuel replaced")
		click(gameplay.fire.position, false)
		check(gameplay.score_controller.points.value == expected_points, "Repeated release cannot score twice")
		await get_tree().process_frame
	check(is_equal_approx(gameplay.hud.progress_bar.value, gameplay.stage_controller.progress), "Шкала следует за прогрессом")
	for locale in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		await get_tree().process_frame

		var first_fuel := gameplay.fuel_controller.fuels[0]
		var key: String = ["FUEL_BRANCH", "FUEL_PAPER", "FUEL_TRASH", "FUEL_LEAF", "FUEL_BUTT", "FUEL_PACK"][first_fuel.kind]
		if first_fuel.stage > 1:
			key = "FUEL_STAGE_%d_%d" % [first_fuel.stage, first_fuel.kind]
		check(first_fuel.label.text == tr("FUEL_VALUE") % [tr(key), first_fuel.point_value], "Локализация топлива")
		check(tr("HUD_POINTS") != "HUD_POINTS", "Перевод загружен")

	for window_size in [Vector2i(480, 900), Vector2i(1600, 600), Vector2i(960, 640)]:
		root.size = window_size
		await get_tree().process_frame
		await get_tree().process_frame
		var visible_rect := root.get_visible_rect()
		check(gameplay.hud.progress_bar.get_global_transform_with_canvas().origin.y < visible_rect.size.y * 0.1, "HUD остаётся над игровым полем")
		var transform := main.world_node.get_global_transform_with_canvas()
		for item in gameplay.fuel_controller.fuels:
			check(visible_rect.encloses(transform * Rect2(item.position + item.bounds.position * item.scale, item.bounds.size * item.scale)), "Топливо помещается в окне")
		fuel = gameplay.fuel_controller.fuels[0]
		expected_points += fuel.point_value
		click(fuel.position, true)
		click(gameplay.fire.position, false)
		check(gameplay.score_controller.points.value == expected_points, "Перетаскивание после изменения окна")
	main.queue_free()
	await get_tree().process_frame
	print("Drag mechanic checks: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	get_tree().quit(0 if failures == 0 else 1)


func click(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = main.world_node.get_global_transform_with_canvas() * position
	event.pressed = pressed
	main._input(event)


func motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = main.world_node.get_global_transform_with_canvas() * position
	main._input(event)


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
