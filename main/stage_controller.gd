class_name StageController

signal changed
signal progress_changed

var stage: int = 0
var highest_stage: int = 0
var progress: float = 0.0
var awaiting_upgrade := false
var helper_count: int = 0
var won := false
var spent_points: float = 0.0
var drain_started := false
var drain_delay_left: float
var stage_scale: float = 1.0
var fire_scale: float = 1.0
var view_scale: float = 1.0
var points: int = 0


func _init() -> void:
	var count: int = Config.stage_upgrade_costs.size()
	assert(Config.stage_progress_drain.size() == count and Config.stage_drain_delay.size() == count)
	drain_delay_left = Config.stage_drain_delay[0]
	assert(count == GlobalConfig.Stage.size())
	assert(Config.stage_fuel_kinds.size() == count and Config.stage_flame_sizes.size() == count)
	assert(Config.stage_reward_multipliers.size() == count)
	assert(Config.stage_flame_tones.size() == count and Config.stage_edge_tones.size() == count)
	for cost in Config.stage_upgrade_costs:
		assert(cost > 0, "Стоимость улучшения должна быть положительной")


func update_score(value: int) -> void:
	highest_stage = maxi(highest_stage, stage)
	points = value
	progress = clampf(float(points - spent_points) / Config.stage_upgrade_costs[stage], 0.0, 1.0)
	won = stage == GlobalConfig.Stage.BLACK_HOLE and progress >= 1.0
	awaiting_upgrade = progress >= 1.0 and stage != GlobalConfig.Stage.PLANET and !won
	stage_scale = pow(Config.stage_scale_factor, stage)
	fire_scale = Config.fire_scale * stage_scale
	view_scale = stage_scale
	changed.emit()


func can_advance() -> bool:
	return stage < Config.stage_upgrade_costs.size() - 1


func helpers_available() -> bool:
	return stage < GlobalConfig.Stage.SURFACE


func choose_helper() -> bool:
	if !awaiting_upgrade or !helpers_available():
		return false

	spent_points += Config.stage_upgrade_costs[stage]
	helper_count += 1
	refresh_stage()
	return true


func choose_next_stage() -> bool:
	if !awaiting_upgrade or !can_advance():
		return false

	spent_points += Config.stage_upgrade_costs[stage]
	stage += 1
	if stage == GlobalConfig.Stage.PLANET:
		spent_points -= Config.planet_starting_fuel
	refresh_stage()
	return true


func regress() -> void:
	stage = maxi(0, stage - 1)
	spent_points = points
	refresh_stage()


func tick(delta: float) -> bool:
	if !drain_started or won or awaiting_upgrade or delta <= 0.0:
		return false

	var paused_time := minf(drain_delay_left, delta)
	drain_delay_left -= paused_time
	var active_time := delta - paused_time
	if active_time <= 0.0:
		return false

	var drain: float = Config.stage_progress_drain[stage] * active_time
	if drain <= 0.0:
		return false

	spent_points = minf(points, spent_points + drain)
	progress = clampf((points - spent_points) / Config.stage_upgrade_costs[stage], 0.0, 1.0)
	progress_changed.emit()
	return progress <= 0.0


func finish_planet() -> void:
	if stage != GlobalConfig.Stage.PLANET:
		return

	stage += 1
	spent_points = points
	refresh_stage()


func refresh_stage() -> void:
	drain_started = false
	drain_delay_left = Config.stage_drain_delay[stage]
	update_score(points)


func reset() -> void:
	drain_started = false
	stage = 0
	highest_stage = 0
	helper_count = 0
	won = false
	spent_points = 0.0
	drain_delay_left = Config.stage_drain_delay[0]
