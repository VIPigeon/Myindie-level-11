class_name ScoreController

var points := ObservableInt.new()


func _init(starting_score: int) -> void:
	points.value = starting_score


func award(value: int) -> void:
	points.value += value
