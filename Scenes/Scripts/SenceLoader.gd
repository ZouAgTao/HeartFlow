extends Node
# 本脚本用于管理场景的加载
# 本脚本为（自动加载）的（单例模式）的（全局脚本）


# 【信号】signal_name()


# 【枚举】ENUM_NAME


# 【常量】CONST_VALUE

const PROGRESS_FILE_NAME = "user://progress.json"

const MAX_STAGE = [0, 4]

# 【导出变量】variant_name


# 【公开成员变量】variant_name[get|set]
var life_num : int = 5
var flight_num : int = 10

# 【私有成员变量】_variant_name

var _progress_data : Dictionary = {
			"stage_main" : 1,
			"stage_vice" : 1,
		}

var _current_sence : Node = null

var _root : Viewport = null


# 【节点变量】variant_name[onready]


# 【虚函数】_function_name

func _ready():
	_check_file_or_new()
	_read_data()
	_init_current_info()


# 【静态函数】functionName


# 【公开成员函数】function_name

func get_life_num() -> int:
	return life_num


func get_flight_num() -> int:
	return flight_num


func save_life_n_fln(s_life_num : int, s_flight_num : int) -> void:
	life_num = s_life_num
	flight_num = s_flight_num


func continue_game_progress() -> void:
	call_deferred("_continue_game_progress")


func go_next_stage() -> void:
	_progress_data.stage_vice += 1
	if _progress_data.stage_vice > MAX_STAGE[_progress_data.stage_main]:
		_progress_data.stage_vice = 1
		_progress_data.stage_main += 1
		
		if _progress_data.stage_main > (len(MAX_STAGE) - 1):
			_game_success()
			return
	
	_store_data()
	continue_game_progress()


func play_again() -> void:
	life_num = 5
	flight_num = 10
	call_deferred("_continue_game_progress")


# 【私有处理函数】_function_name

func _check_file_or_new() -> void:
	var file = File.new()
	
	if not file.file_exists(PROGRESS_FILE_NAME):
		file.open(PROGRESS_FILE_NAME, File.WRITE)
		file.store_line(to_json(_progress_data))
		file.close()


func _read_data() -> void:
	var file = File.new()
	
	file.open(PROGRESS_FILE_NAME, File.READ)
	_progress_data = parse_json(file.get_as_text())
	file.close()


# 【待处理】
func _store_data() -> void:
#	var file = File.new()
#
#	file.open(PROGRESS_FILE_NAME, File.READ)
#	_progress_data = parse_json(file.get_as_text())
#	file.close()
	pass


func _init_current_info() -> void:
	_root = get_tree().get_root()
	_current_sence = _root.get_child(_root.get_child_count() - 1)


func _complete_sence_path(stage_main : int, stage_vice : int) -> String:
	var path : String
	
	match stage_main:
		1:
			path = "res://Scenes/UntitledValley/Stage1_" + str(stage_vice) + "/Stage1_" + str(stage_vice) + ".tscn"
	
	return path


func _continue_game_progress() -> void:
	_current_sence.free()
	
	var sence_resource = ResourceLoader.load(_complete_sence_path(_progress_data.stage_main, _progress_data.stage_vice))
	_current_sence = sence_resource.instance()
	
	_root.add_child(_current_sence)
	get_tree().set_current_scene(_current_sence)


# 游戏通关【待处理】
func _game_success() -> void:
	pass


# 【信号处理函数】_on_func_name()


# 【内部类】ClassName
