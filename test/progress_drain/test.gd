extends Node

var failures: int


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var stages := StageController.new()
	stages.update_score(20)
	var initial := stages.progress
	stages.tick(100.0)
	check(stages.progress == initial and stages.drain_delay_left == Config.stage_drain_delay[0], "До первого сжигания таймер не идёт")
	stages.drain_started = true
	check(!stages.tick(Config.stage_drain_delay[0]), "Во время задержки огонь не угасает")
	check(stages.progress == initial, "Задержка сохраняет шкалу")
	stages.tick(0.5)
	check(is_equal_approx(stages.progress, (20.0 - Config.stage_progress_drain[0] * 0.5) / Config.stage_upgrade_costs[0]), "Шкала плавно убывает с дробной скоростью")
	var previous := stages.progress
	stages.update_score(25)
	check(stages.progress > previous, "Топливо пополняет ту же шкалу")
	stages.update_score(100)
	previous = stages.progress
	stages.tick(100.0)
	check(stages.progress == previous, "Выбор улучшения останавливает дрейн")

	var main: Main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.set_process(false)
	var game := main.gameplay
	game.stage_controller.stage = 2
	game.stage_controller.helper_count = 2
	game.stage_controller.update_score(game.score_controller.points.value)
	game.on_fuel_burned(90)
	game.tick(0.25)
	var remaining_delay := game.stage_controller.drain_delay_left
	game.on_fuel_burned(1)
	check(game.stage_controller.drain_delay_left == remaining_delay, "Повторное кормление не продлевает задержку")
	game.tick(0.01)
	var helper_position := game.helpers[0].position
	var fuel := game.fuel_controller.fuels[-1]
	game.drag_controller.start_drag(fuel.position)
	game.stage_controller.drain_delay_left = 0.0
	game.tick(10.0)
	check(game.stage_controller.stage == 1, "Пустая шкала откатывает ровно на один этап")
	check(game.stage_controller.progress == 0.0, "Прогресс предыдущего этапа начинается с нуля")
	check(game.helpers.size() == 2, "Помощники сохранены")
	check(game.helpers[0].position.is_equal_approx(helper_position / Config.stage_scale_factor), "Позиции помощников масштабируются вниз")
	check(game.drag_controller.dragged_fuel == null, "Откат отменяет перетаскивание")
	check(game.stage_controller.drain_delay_left == Config.stage_drain_delay[1], "Откат возвращает задержку")
	check(!game.stage_controller.drain_started, "После отката таймер ждёт первого кормления")
	check(game.hud.progress_bar.value == 0.0, "Видимая шкала обновлена после угасания")
	game.stage_controller.stage = 0
	game.stage_controller.regress()
	game.stage_controller.drain_delay_left = 0.0
	game.tick(0.1)
	check(game.stage_controller.stage == 0, "Первый этап не уходит в отрицательный индекс")
	main.queue_free()
	await get_tree().process_frame

	var solo := await simulate_town(0)
	var assisted := await simulate_town(2)
	check(!solo, "Ручной сбор раз в секунду не проходит город")
	check(assisted, "Два помощника с ручным сбором проходят город")
	print("Проверки дрейна: %s" % ("ПРОЙДЕНЫ" if failures == 0 else "ОШИБКИ"))
	get_tree().quit(0 if failures == 0 else 1)


func simulate_town(helper_count: int) -> bool:
	seed(42)
	var main: Main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.set_process(false)
	main.gameplay.fire.set_process(false)
	var game := main.gameplay
	game.stage_controller.stage = GlobalConfig.Stage.HOUSE
	game.stage_controller.helper_count = helper_count
	game.stage_controller.update_score(game.score_controller.points.value)
	game.stage_controller.drain_delay_left = Config.stage_drain_delay[GlobalConfig.Stage.HOUSE]
	var passed := false
	var steps: int = 0
	for i in range(1800):
		steps = i
		game.fire._process(0.05)
		game.tick(0.05)
		if game.stage_controller.stage != GlobalConfig.Stage.HOUSE:
			break
		if i % 20 == 19:
			for fuel in game.fuel_controller.fuels:
				if fuel is Car or fuel.reserved_by != null:
					continue
				game.drag_controller.start_drag(fuel.position)
				game.drag_controller.move_drag(Vector2.ZERO)
				game.drag_controller.finish_drag()
				break
		if game.stage_controller.awaiting_upgrade:
			passed = true
			break
		if i % 20 == 0:
			await get_tree().process_frame
	print("Город: помощников=%d, время=%.1f с, пройден=%s" % [helper_count, steps * 0.05, passed])
	main.queue_free()
	await get_tree().process_frame
	return passed


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
