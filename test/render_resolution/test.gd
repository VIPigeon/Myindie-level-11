extends Node

var failures: int


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var main: Main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.set_process(false)
	var window := get_window()
	var game := main.gameplay
	check(game.fire.get_viewport() == main.game_viewport, "Огонь рендерится вместе с миром")
	check(game.hud.get_viewport() == window, "UI находится вне текстуры мира")

	for size in [Vector2i(400, 300), Vector2i(800, 600), Vector2i(1200, 900), Vector2i(1600, 600), Vector2i(480, 900)]:
		window.size = size
		await get_tree().process_frame
		await get_tree().process_frame
		check(main.game_viewport.size == Vector2i(400, 300), "Разрешение мира не зависит от окна")
		check(main.game_image.texture.get_size() == Vector2(400, 300), "Рендер-текстура имеет размер 400×300")
		var image_transform := window.get_stretch_transform() * main.game_image.get_global_transform_with_canvas()
		var shown_size := main.game_image.size * image_transform.get_scale()
		check(shown_size.is_equal_approx(Vector2(size)), "Текстура занимает всё окно")
		var ui_transform := window.get_stretch_transform() * game.hud.stage_progress.get_global_transform_with_canvas()
		var ui_scale := ui_transform.get_scale()
		check(ui_scale.is_equal_approx(Vector2(size) / Vector2(400, 300)), "UI масштабируется вместе с окном")

		var fuel := game.fuel_controller.fuels[0]
		var score_before := game.score_controller.points.value
		click_world(main, fuel.position, true)
		click_world(main, game.fire.position, false)
		check(game.score_controller.points.value == score_before + fuel.point_value, "Перетаскивание работает после изменения окна")

	game.score_controller.points.value = int(ceil(game.stage_controller.spent_points + Config.stage_upgrade_costs[0]))
	await get_tree().process_frame
	var button := game.hud.helper_button
	var button_position := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button_position
		event.pressed = pressed
		window.push_input(event, true)
	await get_tree().process_frame
	check(game.stage_controller.helper_count == 1, "Кнопка масштабированного UI принимает нажатие")

	main.queue_free()
	await get_tree().process_frame
	print("Проверки рендера и масштаба UI: %s" % ("ПРОЙДЕНЫ" if failures == 0 else "ОШИБКИ"))
	get_tree().quit(0 if failures == 0 else 1)


func click_world(main: Main, position: Vector2, pressed: bool) -> void:
	var viewport_position := main.world_node.get_global_transform_with_canvas() * position
	var image_position := viewport_position * main.game_image.size / Vector2(main.game_viewport.size)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = main.game_image.get_global_transform_with_canvas() * image_position
	event.pressed = pressed
	main._input(event)


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
