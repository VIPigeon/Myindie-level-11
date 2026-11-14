class_name FeedFeedback extends Node2D

var pickup := preload("res://game/feedback/pickup.wav")
var drop := preload("res://game/feedback/drop.wav")
var burn := preload("res://game/feedback/burn.wav")
var sound_index := 0


func play_sound(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = Config.feedback_volume_db
	player.pitch_scale = [0.95, 1.0, 1.06, 0.98][sound_index % 4]
	sound_index += 1
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func reward(value: int, origin: Vector2, world_scale: float) -> void:
	play_sound(burn)
	var label := Label.new()
	label.text = "+%d" % value
	label.add_theme_color_override("font_color", Config.palette[7])
	label.add_theme_color_override("font_outline_color", Config.palette[0])
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", Config.feedback_reward_size)
	label.scale = Vector2.ONE * world_scale
	label.position = origin + Vector2(-16, -80) * world_scale
	label.z_index = Config.dragged_z_index + 3
	add_child(label)
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - Config.feedback_reward_rise * world_scale, Config.feed_feedback_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, Config.feed_feedback_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
