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
	stages.helper_count = 2
	stages.stage = GlobalConfig.Stage.HOUSE
	stages.update_score(game.score_controller.points.value)
	game.fuel_controller.tick(0.1)
	game.score_controller.award(Config.stage_upgrade_costs[GlobalConfig.Stage.HOUSE])
	stages.choose_next_stage()
	check(stages.stage == GlobalConfig.Stage.SURFACE, "После дома нет пустого этапа")
	check(!game.hud.helper_button.visible, "На поверхности скрыта покупка помощника")
	check(game.helpers.is_empty() and stages.helper_count == 0, "Помощники удалены при переходе к спутникам")
	check(!game.fire.light.enabled and !game.fire.glow.visible, "На поверхности нет точечного света и ореола")
	check(game.fire.flame_material.shader.resource_path.ends_with("surface.gdshader"), "У поверхности отдельный шейдер")
	game.fire.set_fire_scale(stages.fire_scale)
	main.view_scale = stages.view_scale
	main.apply_camera()
	for window_size in [Vector2i(1000, 750), Vector2i(1600, 600), Vector2i(480, 900)]:
		get_tree().root.size = window_size
		await get_tree().process_frame
		main.apply_camera()
		var capture := game.fire.surface_capture_rect()
		var inset := Vector2.ONE * stages.stage_scale
		for point in [capture.position + inset, Vector2(capture.end.x - inset.x, capture.position.y + inset.y), capture.end - inset]:
			check(game.fire.contains_point(point), "Нижняя полоса принимает предметы по всей ширине окна")
		check(!game.fire.contains_point(Vector2(capture.get_center().x, capture.position.y - inset.y)), "Над полосой предметы не сгорают")
	get_tree().root.size = Vector2i(1000, 750)
	await get_tree().process_frame
	main.apply_camera()
	var flying := game.fuel_controller.fuels[0]
	check(flying.is_flying(), "В космосе появляется летающее топливо")
	var start := flying.position
	game.fuel_controller.tick(0.2)
	check(start != flying.position, "Космические объекты летят")
	game.drag_controller.start_drag(flying.position)
	start = flying.position
	game.fuel_controller.tick(0.2)
	check(start == flying.position, "Захваченный объект не летит")
	game.drag_controller.cancel_drag()
	game.fuel_controller.tick(0.2)
	check(start != flying.position, "После отмены полёт продолжается")
	game.drag_controller.start_drag(flying.position)
	game.drag_controller.move_drag(Vector2(-300, Config.world_size.y * Config.surface_height_ratio) * stages.stage_scale)
	check(game.fire.contains_point(flying.position), "Огонь принимает объекты по ширине нижней части экрана")
	var score_before := game.score_controller.points.value
	game.drag_controller.finish_drag()
	check(game.score_controller.points.value == score_before + flying.point_value, "Награда за сжигание начислена один раз")
	check(flying.burning and !game.fuel_controller.fuels.has(flying), "Горящий объект исключён из игрового топлива")
	check(game.fuel_controller.burning_fuels.has(flying), "Спрайт остаётся на время сгорания")
	game.fuel_controller.tick_burning(Config.fuel_burn_duration + 0.1)
	check(flying.is_queued_for_deletion(), "Сгорание удаляет спрайт после эффекта")
	game.score_controller.points.value = int(ceil(stages.spent_points + Config.stage_upgrade_costs[GlobalConfig.Stage.SURFACE]))
	check(!stages.choose_helper(), "На поверхности нельзя купить помощника даже прямым вызовом")
	stages.choose_next_stage()
	check(game.helpers.is_empty() and !stages.helpers_available(), "На планете помощники не возвращаются")
	check(stages.stage == GlobalConfig.Stage.PLANET and stages.progress > 0, "Планета начинает с запасом топлива")
	check(game.fuel_controller.fuels.size() == 1 and game.fuel_controller.fuels[0].kind == Fuel.Kind.MOON, "У планеты только одна Луна")
	var moon := game.fuel_controller.fuels[0]
	game.drag_controller.start_drag(moon.position)
	game.drag_controller.move_drag(game.fire.position)
	game.drag_controller.finish_drag()
	check(game.fuel_controller.fuels.is_empty(), "После Луны больше нет топлива")
	game.score_controller.award(Config.stage_upgrade_costs[GlobalConfig.Stage.PLANET])
	check(!stages.awaiting_upgrade and !stages.choose_next_stage(), "Планета не открывает обычное меню улучшений")
	stages.drain_delay_left = 0.0
	game.tick(1000.0)
	check(stages.stage == GlobalConfig.Stage.BLACK_HOLE and !game.game_over, "Угасание планеты открывает чёрную дыру")
	for fuel in game.fuel_controller.fuels:
		check(fuel.kind == Fuel.Kind.STAR, "Чёрная дыра питается звёздами")
	var markers := game.hud.stage_progress
	check(markers.markers.size() == 5 and markers.reached_stage == 4, "Секретная стадия не добавляет шестой кружок")
	check(markers.position.x > 0 and markers.position.y > 0, "У шкалы есть отступы от краёв")
	game.score_controller.award(Config.stage_upgrade_costs[GlobalConfig.Stage.BLACK_HOLE])
	check(stages.won and game.hud.victory_panel.visible, "Заполнение чёрной дыры открывает победу")
	check(!game.drag_controller.enabled, "После победы ввод заблокирован")
	var won_progress := stages.progress
	game.tick(100.0)
	check(stages.progress == won_progress, "Победа останавливает дрейн")
	check(!game.hud.header.visible and game.hud.victory_panel.find_children("*", "Button").is_empty(), "На экране победы нет HUD и кнопок")
	game.restart()
	check(!stages.won and stages.stage == GlobalConfig.Stage.EMBER, "После победы можно начать заново")
	main.queue_free()
	await get_tree().process_frame
	print("Проверки поздних стадий и сгорания: %s" % ("ПРОЙДЕНЫ" if failures == 0 else "ОШИБКИ"))
	get_tree().quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
