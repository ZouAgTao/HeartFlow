extends RigidBody2D
# 本脚本用于控制Darts


# 【信号】signal_name()


# 【枚举】ENUM_NAME


# 【常量】CONST_VALUE

const SHOOT_NEP = 100
const SPEED = 1000
const ANGLE_RATE = 2


# 【导出变量】variant_name
export(int) var damage = 1

# 【公开成员变量】variant_name[get|set]


# 【私有成员变量】_variant_name
var _from_who : String
var _has_been_failure : bool = false

# 【节点变量】variant_name[onready]
onready var animated_sprite = get_node("AnimatedSprite")

# 【虚函数】_function_name


# 【静态函数】functionName


# 【公开成员函数】function_name

func is_darts() -> bool:
	return true


func fly(player_position : Vector2, forward_to_right : bool, shoot_forward : int, from_who : String) -> void:
	var motion : Vector2
	
	_from_who = from_who
	match _from_who:
		"player":
			self.set_collision_mask_bit(2, true)
			self.set_collision_mask_bit(5, true)
		_:
			self.set_collision_mask_bit(1, true)
	
	if forward_to_right:
		self.position.x = player_position.x + SHOOT_NEP
		
		if shoot_forward > 0:
			motion = Vector2(ANGLE_RATE, -1)
		elif shoot_forward < 0:
			motion = Vector2(ANGLE_RATE, 1)
		else:
			motion = Vector2(ANGLE_RATE, 0)
	else:
		self.position.x = player_position.x - SHOOT_NEP
		
		if shoot_forward > 0:
			motion = Vector2(-ANGLE_RATE, -1)
		elif shoot_forward < 0:
			motion = Vector2(-ANGLE_RATE, 1)
		else:
			motion = Vector2(-ANGLE_RATE, 0)
	
	self.position.y = player_position.y
	self.linear_velocity = motion.normalized() * SPEED
	animated_sprite.play()


# 【私有处理函数】_function_name


# 【信号处理函数】_on_func_name()

func _on_Darts_body_entered(body : Node):
	if body.has_method("is_darts") and body.is_darts():
		self.set_deferred("gravity_scale", 1)
		$AnimatedSprite.stop()
		$TimerDisapper.start()
		_has_been_failure = true
	
	elif body.has_method("trigger_attacked_by_shoot") and not _has_been_failure:
		body.trigger_attacked_by_shoot(self.position.x <= body.position.x, damage)
#		body.trigger_attacked_by_attacked_b(self.position.x <= body.position.x, damage)
		self.queue_free()
	else:
		self.set_deferred("mode", RigidBody2D.MODE_STATIC)
		$AnimatedSprite.stop()
		$CollisionShape2D.set_deferred("disabled", true)
		$TimerDisapper.start()
		_has_been_failure = true


func _on_TimerDisapper_timeout():
	self.queue_free()


# 【内部类】ClassName
