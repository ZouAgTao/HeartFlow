extends RigidBody2D
# 本脚本用于控制Darts


# 【信号】signal_name()


# 【枚举】ENUM_NAME


# 【常量】CONST_VALUE

const SHOOT_NEP = 100
const SPEED = 1000


# 【导出变量】variant_name
export(int) var damage = 2

# 【公开成员变量】variant_name[get|set]


# 【私有成员变量】_variant_name
var _from_who : String

# 【节点变量】variant_name[onready]
onready var animated_sprite = get_node("AnimatedSprite")

# 【虚函数】_function_name


# 【静态函数】functionName


# 【公开成员函数】function_name

func is_darts() -> bool:
	return false

func is_duye() -> bool:
	return true


func fly(enemy_position : Vector2, player_position : Vector2) -> void:
	var motion : Vector2
	
	self.position = enemy_position
	self.set_collision_mask_bit(1, true)
	
	motion.x = sqrt(abs(player_position.x - enemy_position.x) * 19.6 / 2)
	motion.y = -1 * abs(motion.x)
	if player_position.x < enemy_position.x:
		motion.x = - motion.x
	
	self.linear_velocity = motion * 3.5
	animated_sprite.play()


# 【私有处理函数】_function_name


# 【信号处理函数】_on_func_name()

func _on_Duye_body_entered(body : Node):	
	if body.has_method("trigger_attacked_by_attacked_b"):
		body.trigger_attacked_by_attacked_b(self.position.x <= body.position.x, damage)
#		body.trigger_attacked_by_attacked_b(self.position.x <= body.position.x, damage)
		self.queue_free()
	else:
		self.set_deferred("mode", RigidBody2D.MODE_STATIC)
		$AnimatedSprite.stop()
		$CollisionShape2D.set_deferred("disabled", true)
		$TimerDisapper.start()


func _on_TimerDisapper_timeout():
	self.queue_free()


# 【内部类】ClassName
