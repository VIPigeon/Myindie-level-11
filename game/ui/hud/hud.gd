class_name HUD extends Control

const STAGE_NAMES := ["STAGE_EMBER", "STAGE_CAMP", "STAGE_HOUSE", "STAGE_SURFACE", "STAGE_PLANET", "STAGE_BLACK_HOLE"]

var fuel_tween: Tween

signal helper_chosen
signal stage_chosen
signal restart_chosen

@onready var stage_progress: StageProgress = $Header/StageProgress
@onready var progress_bar: ProgressBar = $Header/ProgressBar
@onready var game_over_panel: Control = $GameOver
@onready var victory_panel: Control = $Victory
@onready var restart_button: Button = $GameOver/Center/Panel/Content/Restart
@onready var stage_name: Label = $Header/Journey
@onready var header: Control = $Header
@onready var choices: Control = $Choices
@onready var helper_button: Button = $Choices/Center/Panel/Content/Buttons/Helper
@onready var stage_button: Button = $Choices/Center/Panel/Content/Buttons/NextStage


func _ready() -> void:
	restart_button.pressed.connect(restart_chosen.emit)
	helper_button.pressed.connect(helper_chosen.emit)
	stage_button.pressed.connect(stage_chosen.emit)


func show_stage(controller: StageController) -> void:
	stage_name.text = STAGE_NAMES[controller.stage]
	header.visible = !controller.won
	progress_bar.value = controller.progress
	stage_progress.show_progress(controller.highest_stage)
	helper_button.visible = controller.helpers_available()
	var opening := !choices.visible and controller.awaiting_upgrade
	choices.visible = controller.awaiting_upgrade
	stage_button.disabled = !controller.can_advance()
	if opening:
		if helper_button.visible:
			helper_button.grab_focus()
		else:
			stage_button.grab_focus()

	if controller.won and !victory_panel.visible:
		choices.hide()
		victory_panel.show()
		get_viewport().gui_release_focus()


func show_game_over() -> void:
	choices.hide()
	game_over_panel.show()
	restart_button.grab_focus()


func pulse_fuel() -> void:
	if fuel_tween != null:
		fuel_tween.kill()
	progress_bar.pivot_offset = progress_bar.size * 0.5
	progress_bar.scale = Vector2(1.04, 1.5)
	fuel_tween = create_tween()
	fuel_tween.tween_property(progress_bar, "scale", Vector2.ONE, Config.feed_feedback_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
