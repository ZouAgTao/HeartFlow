extends CanvasLayer

export(int, 1, 100) var life_num = 5
export(int, 3, 100) var flight_props_num = 10

var _life_num : int = 5
var _flight_props_num : int = 10

func _ready():
	_life_num = AgSenceLoader.get_life_num()
	_flight_props_num = AgSenceLoader.get_flight_num()
	
	_re_paint()

func _re_paint() -> void:
	$UI/LifeProgressBar.value = 1.0 * _life_num / life_num * $UI/LifeProgressBar.max_value
	$UI/FlightPropsNum.text = str(_flight_props_num)


func _on_Player_use_flight_props() -> void:
	_flight_props_num -= 1
	_re_paint()


func _on_Player_change_life_num(damage : int) -> void:
	_life_num -= damage
	
	if _life_num <= 0:
		_life_num = 0
	
	_re_paint()


func _on_Player_die() -> void:
	_life_num = 0
	
	_re_paint()
