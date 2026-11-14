extends Node

var failures: int


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var main: Main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	var fire := main.gameplay.fire
	check(fire.embers is CPUParticles2D and fire.embers.emitting, "Фоновое тление использует частицы Godot")
	check(fire.embers.fixed_fps == 0, "Фоновые частицы обновляются каждый кадр")
	fire.set_stage(GlobalConfig.Stage.HOUSE)
	fire.feed()
	fire.feed()
	var effects: Array[FeedParticles] = []
	var references: Array[WeakRef] = []
	for child in main.world_node.get_children():
		if child is FeedParticles:
			effects.append(child)
			references.append(weakref(child))
	check(effects.size() == 2, "Быстрые кормления не сбрасывают предыдущий выброс")
	for effect in effects:
		check(effect.sparks is CPUParticles2D and effect.embers is CPUParticles2D, "Оба слоя используют частицы Godot")
		check(effect.sparks.fixed_fps == 0 and effect.embers.fixed_fps == 0, "Оба слоя выброса обновляются каждый кадр")
		check(effect.sparks.one_shot and effect.embers.one_shot, "Выброс одноразовый")
		check(effect.sparks.amount == Config.feed_particle_count, "Количество искр из конфига")
		check(effect.hot_color == Config.palette[6], "Палитра соответствует этапу")
		check(!effect.sparks.local_coords, "Частицы остаются в мировых координатах")
	var emitted_size := effects[0].sparks.scale_amount_max
	fire.set_fire_scale(2.0)
	check(effects[0].sparks.scale_amount_max == emitted_size, "Рост огня не увеличивает выпущенные частицы")
	effects.clear()
	await get_tree().create_timer(Config.feed_ember_lifetime * 2.0 + 0.5).timeout
	for reference in references:
		check(reference.get_ref() == null, "Эффект удаляется после завершения обоих эмиттеров")
	main.queue_free()
	await get_tree().process_frame
	print("Проверки частиц: %s" % ("ПРОЙДЕНЫ" if failures == 0 else "ОШИБКИ"))
	get_tree().quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)
