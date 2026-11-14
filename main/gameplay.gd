class_name Gameplay

var world_node: Node2D
var gui_node: Control
var fire: Fire
var hud: HUD
var stage_controller := StageController.new()
var score_controller: ScoreController
var restarting_fire := false
var game_over := false
var fuel_controller: FuelController
var drag_controller: DragController
var helpers: Array[Helper]
var feedback: FeedFeedback

var fire_scene := preload("res://game/fire/fire.tscn")
var hud_scene := preload("res://game/ui/hud/hud.tscn")


func _init(world_node_: Node2D, gui_node_: Control) -> void:
	self.world_node = world_node_
	self.gui_node = gui_node_


func create_game() -> void:
	feedback = FeedFeedback.new()
	world_node.add_child(feedback)

	fire = fire_scene.instantiate()
	world_node.add_child(fire)

	hud = hud_scene.instantiate()
	gui_node.add_child(hud)
	score_controller = ScoreController.new(Config.starting_score)
	hud.helper_chosen.connect(stage_controller.choose_helper)
	hud.stage_chosen.connect(stage_controller.choose_next_stage)
	hud.restart_chosen.connect(restart)

	fuel_controller = FuelController.new(world_node, fire)
	drag_controller = DragController.new(world_node, fuel_controller, fire)
	drag_controller.helpers = helpers
	drag_controller.item_picked.connect(on_item_picked)
	drag_controller.item_dropped.connect(feedback.play_sound.bind(feedback.drop))
	drag_controller.helper_burned.connect(on_helper_burned)
	drag_controller.fuel_burned.connect(on_fuel_burned)
	stage_controller.changed.connect(on_stage_updated)
	stage_controller.progress_changed.connect(on_progress_updated)
	score_controller.points.changed.connect(stage_controller.update_score)
	stage_controller.update_score(score_controller.points.value)


func on_item_picked() -> void:
	feedback.play_sound(feedback.pickup)


func on_fuel_burned(value: int) -> void:
	stage_controller.drain_started = true
	feedback.reward(value, fire.last_feed_position, stage_controller.stage_scale)
	hud.pulse_fuel()
	score_controller.award(value)
	fuel_controller.refill()


func on_stage_updated() -> void:
	var stage_changed := fuel_controller.stage != stage_controller.stage or restarting_fire
	if stage_changed or stage_controller.awaiting_upgrade or stage_controller.won:
		drag_controller.cancel_drag()
	drag_controller.enabled = !stage_controller.awaiting_upgrade and !stage_controller.won
	fire.grow_to(stage_controller.fire_scale)
	fire.set_stage(stage_controller.stage)
	if !stage_controller.helpers_available():
		clear_helpers()
	if stage_changed:
		var scale_ratio := stage_controller.stage_scale / fuel_controller.stage_scale
		for helper in helpers:
			helper.reset_job()
			helper.stage = stage_controller.stage
			helper.position *= scale_ratio
			helper.scale = Vector2.ONE * stage_controller.stage_scale
		fuel_controller.set_stage(stage_controller.stage, stage_controller.stage_scale)
	fuel_controller.refill()
	while helpers.size() < stage_controller.helper_count:
		var helper := Helper.new()
		helper.stage = stage_controller.stage
		helper.fuel_controller = fuel_controller
		helper.fire = fire
		helper.scale = Vector2.ONE * stage_controller.stage_scale
		helper.position = Vector2(fire.radius, fire.radius)
		helper.z_index = Config.dragged_z_index
		world_node.add_child(helper)
		helpers.append(helper)
	hud.show_stage(stage_controller)


func tick(delta: float) -> void:
	fuel_controller.tick_burning(delta)
	if game_over or stage_controller.won or stage_controller.awaiting_upgrade:
		return

	if stage_controller.tick(delta):
		if stage_controller.stage == GlobalConfig.Stage.PLANET:
			stage_controller.finish_planet()
			return
		if stage_controller.stage == GlobalConfig.Stage.EMBER:
			game_over = true
			drag_controller.cancel_drag()
			drag_controller.enabled = false
			for helper in helpers:
				helper.reset_job()
			fuel_controller.clear_burning()
			fire.extinguish()
			hud.show_game_over()
			return
		restarting_fire = true
		stage_controller.regress()
		restarting_fire = false
		return

	fuel_controller.tick(delta)
	if !stage_controller.helpers_available():
		return

	for helper in helpers:
		var value := helper.tick(delta)
		if value > 0:
			on_fuel_burned(value)
		if stage_controller.awaiting_upgrade:
			break


func on_progress_updated() -> void:
	hud.show_stage(stage_controller)


func restart() -> void:
	if !game_over and !stage_controller.won:
		return

	game_over = false
	clear_helpers()
	stage_controller.reset()
	restarting_fire = true
	fire.reignite()
	score_controller.points.value = Config.starting_score
	restarting_fire = false
	hud.game_over_panel.hide()
	hud.victory_panel.hide()


func clear_helpers() -> void:
	for helper in helpers:
		helper.reset_job()
		helper.queue_free()
	helpers.clear()
	stage_controller.helper_count = 0


func on_helper_burned(helper: Helper) -> void:
	helpers.erase(helper)
	stage_controller.helper_count -= 1
	helper.burn(fire.position)
	fuel_controller.burning_fuels.append(helper)
	var reward := int(Config.stage_upgrade_costs[stage_controller.stage] * Config.helper_fuel_ratio)
	on_fuel_burned(reward)
