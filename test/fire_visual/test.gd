extends Node

var failures: int


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var main: Main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	var fire := main.gameplay.fire
	var drag := main.gameplay.drag_controller
	fire.set_process(false)
	var base_radius := fire.radius
	var base_light_scale := fire.light.texture_scale
	fire.show_contact(Vector2(base_radius * 1.5, 0.0))
	fire._process(0.2)
	check(fire.contact_amount > 0.0, "Из костра вырастает локальный выступ")
	check(fire.contact_direction.x > 0.0, "Выступ направлен к точке касания")
	check(fire.light.position == Vector2.ZERO, "Свет костра не сдвигается")
	fire.show_contact(Vector2.ONE * 10000.0)
	check(fire.contact_strength == 0.0, "Вдали от костра индикатор скрыт")
	var fuel := main.gameplay.fuel_controller.fuels[0]
	drag.start_drag(fuel.position)
	drag.move_drag(Vector2(base_radius * 1.3, 0.0))
	check(fire.contact_strength > 0.0, "Перетаскивание показывает индикатор")
	drag.cancel_drag()
	check(fire.contact_strength == 0.0, "Отмена скрывает индикатор")
	fire.feed()
	check(fire.burst > 0.0, "Сжигание вызывает вспышку")
	fire._process(2.0)
	check(fire.burst == 0.0, "Вспышка затухает")
	fire.set_fire_scale(2.0)
	check(is_equal_approx(fire.radius, base_radius * 2.0), "Радиус растёт вместе с огнём")
	check(is_equal_approx(fire.light.texture_scale, base_light_scale * 2.0), "Свет растёт вместе с огнём")
	check(fire.flame.size.is_equal_approx(Vector2(6.0, Config.fire_canvas_top + Config.fire_canvas_bottom) * fire.radius), "Полотно шейдера масштабируется")
	check(fire.contains_point(Vector2(Config.ember_capture_radius * 1.5, 0.0)), "Область приёма топлива масштабируется")
	var second_fire: Fire = load("res://game/fire/fire.tscn").instantiate()
	main.world_node.add_child(second_fire)
	check(second_fire.flame_material != fire.flame_material, "Материалы разных огней независимы")
	main.queue_free()
	await get_tree().process_frame
	print("Проверки огня: %s" % ("ПРОЙДЕНЫ" if failures == 0 else "ОШИБКИ"))
	get_tree().quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
