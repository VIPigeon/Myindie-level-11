extends Node

var failures: int


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	seed(51)
	var main: Main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.set_process(false)
	var game := main.gameplay
	for fuel in game.fuel_controller.fuels:
		check(fuel.kind in [Fuel.Kind.LEAF, Fuel.Kind.BUTT], "Первый этап содержит только листья и окурки")
		check(fuel.art_texture != null and !fuel.label.visible, "Топливо использует арт без подписи")
	check(game.fire.flame_material.shader.resource_path.ends_with("ember.gdshader"), "У окурка отдельный шейдер")
	for fuel in game.fuel_controller.fuels:
		check(fuel.art_bounds.size.is_equal_approx(fuel.art_texture.get_size() * Config.world_pixel_size), "Одинаковый размер пикселя у разных предметов")
	check(is_equal_approx(game.fire.base_sprite.scale.x, Config.world_pixel_size), "Основание огня использует тот же пиксель")
	check(game.fire.base_sprite.texture != null, "Окурок на листе отображается")
	var item := game.fuel_controller.fuels[0]
	check(game.fire.contains_point(Vector2(20, 0)) and !game.fire.contains_point(Vector2(30, 0)), "Маленькая область сжигания у окурка")
	check(game.hud.stage_name.text == "STAGE_EMBER", "HUD показывает название стадии")
	var original_bounds := item.bounds
	game.drag_controller.update_hover(item.position)
	check(item.hovered, "Наведение подсвечивает предмет")
	game.drag_controller.start_drag(item.position)
	game.drag_controller.move_drag(game.fire.position)
	item._process(0.1)
	check(item.heat > 0.0 and item.bounds == original_bounds, "Жар не меняет хитбокс")
	game.drag_controller.cancel_drag()
	check(!item.hovered and item.heat_target == 0.0, "Отмена убирает подсветку и жар")
	game.tick(100.0)
	check(!game.game_over and !game.stage_controller.drain_started, "Без первого кормления огонь не угасает")
	game.drag_controller.start_drag(item.position)
	game.drag_controller.move_drag(game.fire.position)
	game.drag_controller.finish_drag()
	check(game.stage_controller.drain_started, "Первое сжигание запускает таймер")
	game.tick(Config.stage_drain_delay[0])
	check(!game.game_over, "Стартовая задержка защищает игрока")
	game.drag_controller.start_drag(game.fuel_controller.fuels[0].position)
	game.tick(10.0)
	check(game.game_over and game.hud.game_over_panel.visible, "Угасание первого этапа показывает проигрыш")
	check(!game.drag_controller.enabled and game.drag_controller.dragged_fuel == null, "Проигрыш отменяет и блокирует перетаскивание")
	check(!game.fire.flame.visible and !game.fire.light.enabled, "Погасший огонь не горит и не светит")
	game.tick(100.0)
	check(game.game_over, "Нет автоматического перезапуска")
	game.hud.restart_button.pressed.emit()
	check(!game.game_over and game.drag_controller.enabled, "Повторный старт разблокирует игру")
	check(game.stage_controller.progress == 0.0 and game.helpers.is_empty(), "Повторный старт сбрасывает прогресс и помощников")
	check(game.fire.flame.visible and game.fire.light.enabled, "Огонь зажигается снова")
	check(game.stage_controller.drain_delay_left == Config.stage_drain_delay[0], "Повторный старт возвращает задержку")
	game.score_controller.award(Config.stage_upgrade_costs[0])
	game.stage_controller.choose_next_stage()
	check(game.fire.flame_material.shader.resource_path.ends_with("fire.gdshader"), "На костре возвращается основной шейдер")
	var rendered_pixel := 6.0 / float(game.fire.flame_material.get_shader_parameter("pixel_count")) * game.fire.radius * game.fire.flame.scale.x
	check(is_equal_approx(rendered_pixel, Config.world_pixel_size * game.fire.size_multiplier), "Размер пламени не меняет размер пикселя")
	for fuel in game.fuel_controller.fuels:
		check(fuel.kind in [Fuel.Kind.BRANCH, Fuel.Kind.LEAF], "На костре только ветки и листья")
	var branch := game.fuel_controller.fuels[0]
	game.drag_controller.start_drag(branch.position)
	game.drag_controller.move_drag(game.fire.position)
	game.drag_controller.finish_drag()
	game.stage_controller.drain_delay_left = 0.0
	game.tick(100.0)
	check(game.stage_controller.stage == 0 and !game.game_over, "Костёр откатывается к окурку без проигрыша")
	game.score_controller.points.value = int(game.stage_controller.spent_points) + Config.stage_upgrade_costs[0]
	game.stage_controller.choose_helper()
	var helper := game.helpers[0]
	var score_before := game.score_controller.points.value
	game.drag_controller.start_drag(helper.position)
	check(game.drag_controller.dragged_fuel == helper, "Помощника можно схватить")
	game.drag_controller.move_drag(game.fire.position)
	game.drag_controller.finish_drag()
	check(game.helpers.is_empty() and game.stage_controller.helper_count == 0, "Сгоревший помощник удалён")
	check(helper.burning and game.fuel_controller.burning_fuels.has(helper), "Помощник сгорает шейдером")
	check(game.score_controller.points.value == score_before + int(Config.stage_upgrade_costs[0] * Config.helper_fuel_ratio), "Одна награда за помощника")
	game.fuel_controller.tick_burning(Config.fuel_burn_duration)
	main.queue_free()
	await get_tree().process_frame
	print("Проверки первых стадий: %s" % ("ПРОЙДЕНЫ" if failures == 0 else "ОШИБКИ"))
	get_tree().quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
