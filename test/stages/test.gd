extends Node

var failures: int


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	seed(42)
	var main: Main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.set_process(false)
	var game := main.gameplay
	var stages := game.stage_controller
	var ground: ColorRect = main.world_node.get_node("Ground")
	var screen_rect: Rect2 = ground.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, ground.size)
	check(screen_rect.position.length() < 0.01 and (screen_rect.size - get_tree().root.get_visible_rect().size).length() < 0.01, "Поле занимает весь экран")
	check(is_equal_approx(game.hud.progress_bar.get_rect().get_center().x, get_tree().root.get_visible_rect().size.x * 0.5), "Шкала по центру")
	check(!game.hud.choices.visible, "Во время игры видна только шкала")
	var initial_scale := game.fire.target_scale
	var initial_view := stages.view_scale
	game.score_controller.points.value = Config.stage_upgrade_costs[0] / 2
	check(game.fire.target_scale == initial_scale and stages.view_scale == initial_view, "Очки внутри этапа не масштабируют огонь и камеру")
	game.score_controller.points.value = Config.stage_upgrade_costs[0] + 3
	check(game.fire.target_scale == initial_scale and stages.view_scale == initial_view, "Полная шкала не масштабирует огонь до выбора")
	check(stages.stage == 0 and stages.awaiting_upgrade, "Заполнение не переключает этап автоматически")
	check(game.hud.choices.visible and !game.drag_controller.enabled, "Выбор блокирует перетаскивание")
	var paused_fuel := game.fuel_controller.fuels[0]
	game.drag_controller.start_drag(paused_fuel.position)
	check(game.drag_controller.dragged_fuel == null, "Нельзя начать перетаскивание за модальным окном")
	var max_scale := game.fire.target_scale
	game.hud.helper_button.pressed.emit()
	check(game.helpers.size() == 1 and stages.stage == 0, "Помощник добавлен без смены этапа")
	check(stages.points - stages.spent_points == 3, "Лишние очки сохраняются")
	check(game.fire.target_scale == max_scale, "Покупка помощника не уменьшает огонь")
	check(!stages.choose_helper(), "Повторное нажатие не даёт бесплатного помощника")
	var before := game.score_controller.points.value
	for i in range(1000):
		game.tick(0.02)
		if game.score_controller.points.value > before:
			break
	check(game.score_controller.points.value > before, "Помощник действительно доставляет топливо и начисляет очки")
	game.score_controller.points.value = stages.spent_points + Config.stage_upgrade_costs[0]
	game.hud.helper_button.pressed.emit()
	game.tick(0.01)
	check(game.helpers.size() == 2, "Можно нанять несколько помощников")
	check(game.helpers[0].target != game.helpers[1].target, "Помощники не выбирают одно топливо")
	var intercepted := game.helpers[0].target
	game.drag_controller.start_drag(intercepted.position)
	check(game.drag_controller.dragged_fuel == intercepted, "Игрок перехватывает цель идущего помощника")
	check(game.helpers[0].target == null and intercepted.reserved_by == null, "Помощник сразу освобождает перехваченную цель")
	game.helpers[0].tick(0.0)
	check(game.helpers[0].target != null and game.helpers[0].target != intercepted, "Помощник выбирает другую цель")
	var awarded_before := game.score_controller.points.value
	game.drag_controller.move_drag(Vector2.ZERO)
	game.drag_controller.finish_drag()
	check(game.score_controller.points.value == awarded_before + intercepted.point_value, "Перехваченное топливо начисляется один раз")
	var carried := game.helpers[0].target
	game.helpers[0].carrying = true
	game.drag_controller.start_drag(carried.position)
	check(game.drag_controller.dragged_fuel == null, "Предмет в руках помощника остаётся занят")
	game.helpers[0].carrying = false
	var helper_count := game.helpers.size()
	game.score_controller.points.value = stages.spent_points + Config.stage_upgrade_costs[0]
	var helper_position := game.helpers[0].position
	game.tick(1.0)
	check(game.helpers[0].position == helper_position, "Помощники ждут во время выбора")
	game.hud.stage_button.pressed.emit()
	check(is_equal_approx(game.fire.target_scale, initial_scale * Config.stage_scale_factor), "Огонь увеличивается только после перехода")
	check(is_equal_approx(stages.view_scale, initial_view * Config.stage_scale_factor), "Камера отдаляется только после перехода")
	check(stages.stage == 1 and game.helpers.size() == helper_count, "Помощник сохраняется при переходе")
	check(game.fire.flame_material.get_shader_parameter("flame_color") == Config.palette[Config.stage_flame_tones[1]], "Палитра этапа применена")
	game.score_controller.points.value = stages.spent_points + Config.stage_upgrade_costs[1]
	game.hud.stage_button.pressed.emit()
	check(stages.stage == GlobalConfig.Stage.HOUSE, "Доступен городской этап")
	for i in range(Config.car_count):
		game.fuel_controller.tick(0.1)
	var car: Car
	for fuel in game.fuel_controller.fuels:
		if fuel is Car:
			car = fuel
	check(car != null, "На городском этапе появляются машины")
	car.position.x = car.road_half_width * 2.0
	car.tick(0.01)
	check(car.position.x < 0.0, "Машина возвращается после выхода за экран")
	var car_position := car.position
	game.fuel_controller.tick(0.1)
	check(car.position != car_position, "Машины движутся")
	game.drag_controller.start_drag(car.position)
	check(game.drag_controller.dragged_fuel == car, "Машину можно поймать")
	car_position = car.position
	game.fuel_controller.tick(0.2)
	check(car.position == car_position, "Пойманная машина стоит")
	game.drag_controller.cancel_drag()
	game.fuel_controller.tick(0.2)
	check(car.position != car_position, "После отмены машина продолжает движение")
	game.drag_controller.start_drag(car.position)
	before = game.score_controller.points.value
	game.drag_controller.move_drag(Vector2.ZERO)
	game.drag_controller.finish_drag()
	check(game.score_controller.points.value == before + Config.car_points, "Сжигание машины начисляет награду один раз")
	game.score_controller.points.value = stages.spent_points + Config.stage_upgrade_costs[stages.stage]
	game.hud.stage_button.pressed.emit()
	check(stages.stage == GlobalConfig.Stage.SURFACE, "После дома идёт поверхность планеты")
	game.score_controller.points.value = stages.spent_points + Config.stage_upgrade_costs[stages.stage]
	stages.choose_next_stage()
	check(stages.stage == GlobalConfig.Stage.PLANET, "После поверхности идёт планета")
	var moon := game.fuel_controller.fuels[0]
	game.drag_controller.start_drag(moon.position)
	game.drag_controller.move_drag(game.fire.position)
	game.drag_controller.finish_drag()
	stages.drain_delay_left = 0.0
	game.tick(1000.0)
	check(stages.stage == GlobalConfig.Stage.BLACK_HOLE, "Угасание планеты открывает секретный этап")
	for fuel in game.fuel_controller.fuels:
		check(!(fuel is Car), "Машины удалены после выхода из города")
	game.score_controller.points.value = stages.spent_points + Config.stage_upgrade_costs[stages.stage]
	check(game.hud.stage_button.disabled and !stages.choose_next_stage(), "На последнем этапе нельзя выйти за список")
	check(stages.won and game.hud.victory_panel.visible, "Последний этап завершается победой")
	main.queue_free()
	await get_tree().process_frame
	print("Проверки улучшений, помощников и машин: %s" % ("ПРОЙДЕНЫ" if failures == 0 else "ОШИБКИ"))
	get_tree().quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
