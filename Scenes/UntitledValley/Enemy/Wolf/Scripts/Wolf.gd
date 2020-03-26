extends KinematicBody2D

# 【常量】


# 【枚举】

enum ANIMATION_STATUS {
	IDLE,
	MOVE,
	JUMP_UP,
	JUMP_DOWN,
	ATTACK_A,
	ATTACK_B,
	SHOOT,
	ATTACKED,
	DIE,
	FLASH,
	KILL,
	HEART_LESS
}


# 【导出变量】

# 数据变量
export(int) var attack_a_damage = 1
export(PackedScene) var flight_props
export(int) var life_num = 0
export(int) var flight_props_num = 0
export(float) var speed = 300
export(float) var double_click_time = 0.25
export(float) var flash_speed = 500
export(float) var flash_hard_time = 0.1
export(float) var gravity = 19.6
export(float) var jump_force = 850
export(float) var attack_hard_time = 0.2
export(float) var shoot_hard_time = 0.35
export(float) var attacked_hard_time = 0.2
export(float) var attack_b_nep_time = 0.35
export(float,0,1) var speed_slow_mode_rate = 0.5
export(float,0,1) var jumpforce_slow_mode_rate = 0.5
export(float) var kill_check_time = 1.0

# 状态变量
export(bool) var is_alive = true
export(bool) var is_face_to_right = false

# 使能变量
export(bool) var can_gravity = true
export(bool) var can_move = true
export(bool) var can_jump = true
export(bool) var can_attack = true
export(bool) var can_attack_b = false
export(bool) var can_shoot = false
export(bool) var can_hreat_less = false
export(bool) var can_breath = false
export(bool) var can_flash = false
export(bool) var can_attacked = true
export(bool) var can_kill = false


# 【私有变量】

# 测试变量
var _life = 5

var _body_players = []

# 趋势变量
var _will_move : bool = false
var _will_move_to_right : bool = true
var _will_jump : bool = false
var _will_fall : bool = false
var _will_attack : bool = false
var _will_shoot : bool = false
var _will_forward_to_up : bool = false
var _will_forward_to_down : bool = false
var _will_flash : bool = false
var _will_kill : bool = false
var _will_heart_less : bool = false

var _will_attacked_by_attack_a : bool = false
var _will_attacked_by_attack_b : bool = false
var _will_attacked_by_shoot : bool = false
var _will_die : bool = false

# 状态变量
var _last_animation_status = ANIMATION_STATUS.IDLE
var _now_animation_status = ANIMATION_STATUS.IDLE

var _attack_end : bool = false
var _shoot_end : bool = false
var _is_attack_mode_b : bool = false

var _is_attacked : bool = false
var _attacked_by_to_right_attack = true

var _enable_flash : bool = false
var _flash_end : bool = false
var _air_flash : bool = true

var _check_kill : bool = false
var _kill_end : bool = false

var _check_heart_less : bool = false
var _heart_less_end : bool = false

var _motion : Vector2 = Vector2()

# 独有变量

var player : Player = null
var _can_attack_player : bool = false

# 【虚方法】

func _ready():
	$Animation.play()
	$Animation.flip_h = is_face_to_right
	
	_timer_init()
	_life = life_num


func _process(delta):
	_reset_willing()
	
	if is_alive:
#		_process_input()
		_process_ai()
		_blend_status()
	
	_update_animation()

func _physics_process(delta):
	_motion = self.move_and_slide(_motion, Vector2.UP, true)


# 【公有方法】

# 外界事件触发输入
func trigger_attacked_by_attacked_a(is_attack_forward_to_right : bool, damage : int) -> bool:
	if can_attacked:
		# 由damage处理伤害的计算
		_make_damage(damage)
		
		# attack_forward产生方向性的attacked的趋势
		_want_attacked_by_attack_a(is_attack_forward_to_right)
	
		# Player不具有格挡能力，所以直接返回true
		return true
	else:
		return false


func trigger_attacked_by_attacked_b(is_attack_forward_to_right : bool, damage : int) -> bool:
	if can_attacked:
		# 由damage处理伤害的计算
		_make_damage(damage)
		
		# attack_forward产生方向性的attacked的趋势
		_want_attacked_by_attack_b(is_attack_forward_to_right)
		
		# Player不具有格挡能力，所以直接返回true
		return true
	else:
		return false


func trigger_attacked_by_shoot(is_attack_forward_to_right : bool, damage : int) -> bool:
	if can_attacked:
		# 由damage处理伤害的计算
		_make_damage(damage)
		
		# attack_forward产生方向性的attacked的趋势
		_want_attacked_by_shoot(is_attack_forward_to_right)
		
		# Player不具有格挡能力，所以直接返回true
		return true
	else:
		return false


# 触发被即死（秒杀）
func trigger_die_by_anyway() -> void:
	# 处理伤害的计算
	_make_die()
	
	# 产生死亡趋势
	_want_die()


# 【私有方法】

# 重置趋势

# 初始化计数器时间
func _timer_init() -> void:
	$AttackHardTimer.wait_time = attack_hard_time
	$ShootHardTimer.wait_time = shoot_hard_time
	$AttackABHardTimer.wait_time = attack_hard_time * 0.5
	$AttackedHardTimer.wait_time = attacked_hard_time
	$AttackBNepTimer.wait_time = attack_b_nep_time
	$FlashCheckTimer.wait_time = double_click_time
	$FlashHardTimer.wait_time = flash_hard_time
	$KillCheckTimer.wait_time = kill_check_time
	$HeartLessCheckTimer.wait_time = kill_check_time


func _reset_willing() -> void:
	_will_move = false
	_will_move_to_right = is_face_to_right
	_will_jump = false
	_will_fall = not self.is_on_floor()
	_will_attack = false
	_will_shoot = false
	_will_forward_to_up = false
	_will_forward_to_down = false
	_will_flash = false
	_will_kill = false
	_will_heart_less = false
	if self.is_on_floor():
		_air_flash = true
	
	# 默认物理状态更新
	_motion.x = 0
	_motion.y += gravity if can_gravity else 0.0


# 更新当前的动画
func _update_animation() -> void:
	match _now_animation_status:
		ANIMATION_STATUS.IDLE:
			$Animation.animation = "idle"
		
		ANIMATION_STATUS.MOVE:
			$Animation.animation = "move"
			$Animation.flip_h = is_face_to_right
		
		ANIMATION_STATUS.JUMP_UP:
			$Animation.animation = "jump_up"
			$Animation.flip_h = is_face_to_right
		
		ANIMATION_STATUS.JUMP_DOWN:
			$Animation.animation = "jump_down"
			$Animation.flip_h = is_face_to_right
		
		ANIMATION_STATUS.ATTACK_A:
			$Animation.animation = "attack_a"
		
		ANIMATION_STATUS.ATTACK_B:
			$Animation.animation = "attack_b"
		
		ANIMATION_STATUS.SHOOT:
			$Animation.animation = "shoot"
		
		ANIMATION_STATUS.FLASH:
			$Animation.animation = "flash"
		
		ANIMATION_STATUS.KILL:
			$Animation.animation = "kill"
		
		ANIMATION_STATUS.HEART_LESS:
			$Animation.animation = "heart_less"
		
		ANIMATION_STATUS.ATTACKED:
			$Animation.animation = "attacked"
		
		ANIMATION_STATUS.DIE:
			$Animation.animation = "die"


# 【〇】核心【〇】⚪
# 有机混合处理所有的状态，并完成动画模式和物理行为的计算
func _blend_status() -> void:
	match _now_animation_status:
		
		# 当前为【idle】状态
		ANIMATION_STATUS.IDLE:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.ATTACKED
				
				# 物理状态变更
				if _will_attacked_by_attack_b:
					_motion.y = -jump_force * jumpforce_slow_mode_rate
				
				return
			
			if _will_fall:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.JUMP_DOWN
				
				# 物理状态变更
				
				return
			
			# 无行为情况
			if not _will_move and not _will_jump and not _will_attack and not _will_shoot and not _will_flash and not _will_kill and not _will_heart_less:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.IDLE
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_heart_less:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.HEART_LESS
					
					# 物理状态变更
					_motion.y = 0
					
					return
				
				if _will_kill:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.KILL
					
					# 物理状态变更
					_motion.y = 0
					
					return
				
				if _will_flash:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.FLASH
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = flash_speed
					else:
						_motion.x = -flash_speed
					
					return
				
				if _will_move:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.MOVE
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = speed
					else:
						_motion.x = -speed
				
				if _will_jump:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.JUMP_UP
					
					# 物理状态变更
					_motion.y = -jump_force
				
				if _will_attack:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					if not _is_attack_mode_b:
						_now_animation_status = ANIMATION_STATUS.ATTACK_A
					else:
						_is_attack_mode_b = false
						_now_animation_status = ANIMATION_STATUS.ATTACK_B
					
					# 物理状态变更
					pass
				
				elif _will_shoot:
					_shoot_darts()
					
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.SHOOT
					
					# 物理状态变更
					pass
		
		# 当前为【move】状态
		ANIMATION_STATUS.MOVE:
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.ATTACKED
				
				# 物理状态变更
				if _will_attacked_by_attack_b:
					_motion.y = -jump_force * jumpforce_slow_mode_rate
				
				return
			
#			if _will_fall:
#				# 动画状态变更
#				_last_animation_status = _now_animation_status
#				_now_animation_status = ANIMATION_STATUS.JUMP_DOWN
#
#				# 物理状态变更
#
#				return
			
			# 无行为情况
			if not _will_move and not _will_jump and not _will_attack and not _will_shoot and not _will_flash:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.IDLE
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_flash:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.FLASH
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = flash_speed
					else:
						_motion.x = -flash_speed
					
					return
				
				if _will_move:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.MOVE
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = speed
					else:
						_motion.x = -speed
				
				if _will_jump:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.JUMP_UP
					
					# 物理状态变更
					_motion.y = -jump_force
				
				if _will_attack:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					if not _is_attack_mode_b:
						_now_animation_status = ANIMATION_STATUS.ATTACK_A
					else:
						_is_attack_mode_b = false
						_now_animation_status = ANIMATION_STATUS.ATTACK_B
					
					# 物理状态变更
					pass
				
				elif _will_shoot:
					_shoot_darts()
					
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.SHOOT
					
					# 物理状态变更
					pass
		
		# 当前为【jump_up】状态
		ANIMATION_STATUS.JUMP_UP:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.ATTACKED
				
				# 物理状态变更
				if _will_attacked_by_attack_b:
					_motion.y = -jump_force * jumpforce_slow_mode_rate
				else:
					_motion.y = 0
				
				return
			
			if _motion.y >= 0:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.JUMP_DOWN
				
				# 物理状态变更
				
				return
			
			# 无行为情况
			if not _will_move and not _will_attack and not _will_shoot and not _will_flash:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.JUMP_UP
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_flash:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.FLASH
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = flash_speed
					else:
						_motion.x = -flash_speed
					
					return
				
				if _will_move:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.JUMP_UP
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = speed
					else:
						_motion.x = -speed
				
				if _will_attack:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					if not _is_attack_mode_b:
						_now_animation_status = ANIMATION_STATUS.ATTACK_A
					else:
						_is_attack_mode_b = false
						_now_animation_status = ANIMATION_STATUS.ATTACK_B
					
					# 物理状态变更
					pass
				
				elif _will_shoot:
					_shoot_darts()
					
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.SHOOT
					
					# 物理状态变更
					pass
		
		# 当前为【jump_down】状态
		ANIMATION_STATUS.JUMP_DOWN:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.ATTACKED
				
				# 物理状态变更
				if _will_attacked_by_attack_b:
					_motion.y = -jump_force * jumpforce_slow_mode_rate
				
				return
			
			if not _will_fall:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.IDLE
				
				# 物理状态变更
				
				return
			
			# 无行为情况
			if not _will_move and not _will_attack and not _will_shoot and not _will_flash:
				# 动画状态变更
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.JUMP_DOWN
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_flash:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.FLASH
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = flash_speed
					else:
						_motion.x = -flash_speed
					
					return
				
				if _will_move:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.JUMP_DOWN
					is_face_to_right = _will_move_to_right
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = speed
					else:
						_motion.x = -speed
				
				if _will_attack:
					# 动画状态变更
					_last_animation_status = _now_animation_status
					if not _is_attack_mode_b:
						_now_animation_status = ANIMATION_STATUS.ATTACK_A
					else:
						_is_attack_mode_b = false
						_now_animation_status = ANIMATION_STATUS.ATTACK_B
					
					# 物理状态变更
					pass
				
				elif _will_shoot:
					_shoot_darts()
					
					# 动画状态变更
					_last_animation_status = _now_animation_status
					_now_animation_status = ANIMATION_STATUS.SHOOT
					
					# 物理状态变更
					pass
		
		# 当前为【attack_a】状态
		ANIMATION_STATUS.ATTACK_A:
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				# 动画状态变更
				_now_animation_status = ANIMATION_STATUS.ATTACKED
				
				$AttackHardTimer.stop()
				$AttackABHardTimer.stop()
				_attack_end = false
				_is_attack_mode_b = false
				
				# 物理状态变更
				if _will_attacked_by_attack_b:
					_motion.y = -jump_force * jumpforce_slow_mode_rate
				
				return
			
			if _attack_end:
				_attack_end = false
				_now_animation_status = _last_animation_status
				return
			
			# 无行为情况
			if not _will_move and not _will_kill:
				pass
				# 动画状态变更
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_kill:
					# 动画状态变更
					_now_animation_status = ANIMATION_STATUS.KILL
					
					$AttackHardTimer.stop()
					$AttackABHardTimer.stop()
					_attack_end = false
					_is_attack_mode_b = false
					
					# 物理状态变更
					_motion.y = 0
					
					return
				
				if _will_move:
					# 动画状态变更
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = speed * speed_slow_mode_rate
					else:
						_motion.x = -speed * speed_slow_mode_rate
		
		# 当前为【attack_b】状态
		ANIMATION_STATUS.ATTACK_B:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _attack_end:
				_attack_end = false
				_now_animation_status = _last_animation_status
				return
			
			# 无行为情况
			if not _will_move and not _will_kill:
				pass
				# 动画状态变更
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_kill:
					# 动画状态变更
					_now_animation_status = ANIMATION_STATUS.KILL
					
					$AttackHardTimer.stop()
					$AttackABHardTimer.stop()
					_attack_end = false
					_is_attack_mode_b = false
					
					# 物理状态变更
					_motion.y = 0
					
					return
				
				if _will_move:
					# 动画状态变更
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = speed * speed_slow_mode_rate
					else:
						_motion.x = -speed * speed_slow_mode_rate
		
		# 当前为【shoot】状态
		ANIMATION_STATUS.SHOOT:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				# 动画状态变更
				_now_animation_status = ANIMATION_STATUS.ATTACKED
				
				$ShootHardTimer.stop()
				_shoot_end = false
				
				# 物理状态变更
				if _will_attacked_by_attack_b:
					_motion.y = -jump_force * jumpforce_slow_mode_rate
				
				return
			
			if _shoot_end:
				_shoot_end = false
				_now_animation_status = _last_animation_status
				return
			
			# 无行为情况
			if not _will_move and not _will_kill:
				pass
				# 动画状态变更
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_kill:
					# 动画状态变更
					_now_animation_status = ANIMATION_STATUS.KILL
					
					$ShootHardTimer.stop()
					_shoot_end = false
					
					# 物理状态变更
					_motion.y = 0
					
					return
				
				if _will_move:
					# 动画状态变更
					
					# 物理状态变更
					if _will_move_to_right:
						_motion.x = speed * speed_slow_mode_rate
					else:
						_motion.x = -speed * speed_slow_mode_rate
		
		# 当前为【attacked】状态
		ANIMATION_STATUS.ATTACKED:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if not _is_attacked:
				# 动画状态变更
				_now_animation_status = _last_animation_status
				
				# 物理状态变更
				
				return
			
			# 无行为情况
			if not _will_attacked_by_shoot and not _will_attacked_by_attack_a and not _will_attacked_by_attack_b:
				pass
				# 动画状态变更
				
				# 物理状态变更
			
			# 有行为情况
			else:
				if _will_attacked_by_attack_a:
					pass
					# 动画状态变更
					is_face_to_right = not _attacked_by_to_right_attack
					
					# 物理状态变更
				
				if _will_attacked_by_shoot:
					# 动画状态变更
					is_face_to_right = not _attacked_by_to_right_attack
					
					# 物理状态变更
					if _attacked_by_to_right_attack:					
						_motion.x = speed * speed_slow_mode_rate
					else:
						_motion.x = -speed * speed_slow_mode_rate
				
				if _will_attacked_by_attack_b:
					# 动画状态变更
					is_face_to_right = not _attacked_by_to_right_attack
					
					# 物理状态变更
					if _attacked_by_to_right_attack:					
						_motion.x = speed
					else:
						_motion.x = -speed

		# 当前为【flash】状态
		ANIMATION_STATUS.FLASH:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				_is_attacked = false
				_will_attacked_by_attack_a = false
				_will_attacked_by_attack_b = false
				_will_attacked_by_shoot = false
			
			if _flash_end:
				_flash_end = false
				_now_animation_status = _last_animation_status
				can_attacked = true
				return
			else:
				can_attacked = false
			
			# 无行为情况
			if true:
				# 动画状态变更
				is_face_to_right = _will_move_to_right
				
				# 物理状态变更
				if _will_move_to_right:
					_motion.x = flash_speed
				else:
					_motion.x = -flash_speed
				
				_motion.y = 0
			
			# 有行为情况
			else:
				pass

		# 当前为【kill】状态
		ANIMATION_STATUS.KILL:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				_is_attacked = false
				_will_attacked_by_attack_a = false
				_will_attacked_by_attack_b = false
				_will_attacked_by_shoot = false
			
			if _kill_end:
				_kill_end = false
				_now_animation_status = _last_animation_status
				can_attacked = true
				return
			else:
				can_attacked = false
			
			# 无行为情况
			if true:
				# 动画状态变更
				
				# 物理状态变更
				
				_motion.y = 0
			
			# 有行为情况
			else:
				pass

		# 当前为【heart_less】状态
		ANIMATION_STATUS.HEART_LESS:
			
			# 强制特定事件
			if _will_die:
				_will_die = false
				is_alive = false
				_last_animation_status = _now_animation_status
				_now_animation_status = ANIMATION_STATUS.DIE
				
				return
			
			if _is_attacked:
				# 动画状态变更
				_now_animation_status = ANIMATION_STATUS.ATTACKED
				
				_will_heart_less = false
				_heart_less_end = false
				
				# 物理状态变更
				if _will_attacked_by_attack_b:
					_motion.y = -jump_force * jumpforce_slow_mode_rate
				
				return
			
			if _heart_less_end:
				_heart_less_end = false
				_now_animation_status = _last_animation_status
			
			# 无行为情况
			if true:
				# 动画状态变更
				
				# 物理状态变更
				
				_motion.y = 0
			
			# 有行为情况
			else:
				pass


# 处理输入转到“趋势处理函数”进行
func _process_input() -> void:
	if Input.is_action_just_pressed("control_left"):
		_want_to_left_flash()
	elif Input.is_action_pressed("control_left"):
		_want_to_left()
	
	if Input.is_action_just_pressed("control_right"):
		_want_to_right_flash()
	elif Input.is_action_pressed("control_right"):
		_want_to_right()
	
	if Input.is_action_pressed("control_up"):
		_want_to_up()
	
	if Input.is_action_pressed("control_down"):
		_want_to_down()
	
	if Input.is_action_just_pressed("control_jump"):
		_want_to_jump()
	
	if Input.is_action_just_pressed("control_attack"):
		_want_to_attack()
	if Input.is_action_pressed("control_attack"):
		_want_to_kill()
	if Input.is_action_just_released("control_attack"):
		_want_to_stop_kill()
	
	if Input.is_action_just_pressed("control_shoot"):
		_want_to_shoot()
	
	if Input.is_action_just_pressed("control_breath"):
		_want_to_breath()
	if Input.is_action_pressed("control_breath"):
		_want_to_heart_less()
	if Input.is_action_just_released("control_breath"):
		_want_to_stop_heart_less()


# AI处理
func _process_ai() -> void:
	if player:
		if player.position.x + 1 < self.position.x:
			_want_to_left()
		elif player.position.x - 1 > self.position.x:
			_want_to_right()
		else:
			pass
		
		if _can_attack_player and not _attack_end:
			_want_to_jump()
			_want_to_attack()


# 趋势处理函数
# 左移
func _want_to_left() -> void:
	if can_move:
		_will_move = true
		_will_move_to_right = false


# 左闪避
func _want_to_left_flash() -> void:
	if can_flash and _air_flash:
		if not _enable_flash:
			_enable_flash = true
			$FlashCheckTimer.start()
		else:
			$FlashCheckTimer.stop()
			_enable_flash = false
			_will_flash = true
			_will_move_to_right = false
			_air_flash = false


# 右移
func _want_to_right() -> void:
	if can_move:
		_will_move = true
		_will_move_to_right = true


# 右闪避
func _want_to_right_flash() -> void:
	if can_flash and _air_flash:
		if not _enable_flash:
			_enable_flash = true
			$FlashCheckTimer.start()
		else:
			$FlashCheckTimer.stop()
			_enable_flash = false
			_will_flash = true
			_will_move_to_right = true
			_air_flash = false


# 向上
func _want_to_up() -> void:
	_will_forward_to_up = true


# 向下
func _want_to_down() -> void:
	_will_forward_to_down = true


# 跳跃
func _want_to_jump() -> void:
	if can_jump:
		_will_jump = true


# 攻击
func _want_to_attack() -> void:
	if can_attack:
		_will_attack = true
	
	if can_kill:
		_check_kill = false
		$KillCheckTimer.stop()
		$KillCheckTimer.start()


# 处决
func _want_to_kill() -> void:
	if can_kill and _check_kill:
		_will_kill = true
		_check_kill = false
		_kill_end = false


# 取消处决
func _want_to_stop_kill() -> void:
	_check_kill = false
	$KillCheckTimer.stop()


# 射击
func _want_to_shoot() -> void:
	if can_shoot:
		_will_shoot = true


# 呼吸
func _want_to_breath() -> void:
	if can_breath:
		$AnPy.play("breath")
	
	if can_hreat_less:
		_check_heart_less = false
		$HeartLessCheckTimer.stop()
		$HeartLessCheckTimer.start()


# 心无
func _want_to_heart_less() -> void:
	if can_hreat_less and _check_heart_less:
		$HeartLessCheckTimer.stop()
		_will_heart_less = true
		_check_heart_less = false
		_heart_less_end = false


# 取消心无
func _want_to_stop_heart_less() -> void:
	_heart_less_end = true


# 被攻击A
func _want_attacked_by_attack_a(is_attack_forward_to_right : bool) -> void:
	_attacked_by_to_right_attack = is_attack_forward_to_right
	_is_attacked = true
	_will_attacked_by_attack_a = true


# 被攻击B
func _want_attacked_by_attack_b(is_attack_forward_to_right : bool) -> void:
	_attacked_by_to_right_attack = is_attack_forward_to_right
	_is_attacked = true
	_will_attacked_by_attack_b = true


# 被射击
func _want_attacked_by_shoot(is_attack_forward_to_right : bool) -> void:
	_attacked_by_to_right_attack = is_attack_forward_to_right
	_is_attacked = true
	_will_attacked_by_shoot = true


# 死亡
func _want_die() -> void:
	_will_die = true
	_become_dead_body()

# 数据变更

# 结算伤害
func _make_damage(damage : int) -> void:
	if _life > 0:
		_life -= damage
		if _life <= 0:
			_want_die()

func _make_die() -> void:
	_life = 0

# 对外行为

func _shoot_darts() -> void:
	
	var flight_forward = 0
	if _will_forward_to_up:
		flight_forward = 1
	elif _will_forward_to_down:
		flight_forward = -1
	
	if flight_props:
		var flight_props_inst = flight_props.instance()
		self.get_parent().add_child(flight_props_inst)
		
		if flight_props_inst.has_method("fly"):
			flight_props_inst.fly(self.position, is_face_to_right, flight_forward, "player")


func _become_dead_body() -> void:
	# 碰撞层更改
	# (L3 | M1 M4) --> (L7 | M1)
	
	# L3【敌人层】OFF
	# L7【尸体层】ON
	self.set_collision_layer_bit(2, false)
	self.set_collision_layer_bit(6, true)
	
	# 碰撞遮罩更改
	
	# M4【玩家攻击判定】OFF
	self.set_collision_mask_bit(3, false)


func _die_end():
	var parent = self.get_parent()
	if parent.has_method("enemy_die"):
		parent.enemy_die()


func _check_breath() -> void:
	print("怪物不会呼吸")

func _make_attack_a() -> void:
	if is_face_to_right:
		for body in _body_players:
			if body.has_method("trigger_attacked_by_attacked_a"):
				body.trigger_attacked_by_attacked_a(is_face_to_right, attack_a_damage)
	else:
		for body in _body_players:
			if body.has_method("trigger_attacked_by_attacked_a"):
				body.trigger_attacked_by_attacked_a(is_face_to_right, attack_a_damage)


# 【信号处理】

func _on_Animation_animation_finished():
	match $Animation.animation:
		"attack_a":
			if not can_attack_b:
				$AttackHardTimer.start()
			else:
				$AttackABHardTimer.start()
		
		"attack_b":
			$AttackHardTimer.start()
		
		"shoot":
			$ShootHardTimer.start()
		
		"flash":
			$FlashHardTimer.start()
		
		"attacked":
			$AttackedHardTimer.start()
		
		"die":
			_die_end()
		
		"kill":
			_kill_end = true


func _on_AttackHardTimer_timeout():
	_attack_end = true


func _on_AttackABHardTimer_timeout():
	_is_attack_mode_b = true
	_attack_end = true
	$AttackBNepTimer.start()


func _on_ShootHardTimer_timeout():
	_shoot_end = true


func _on_AttackBNepTimer_timeout():
	_is_attack_mode_b = false


func _on_AttackedHardTimer_timeout():
	_is_attacked = false
	_will_attacked_by_attack_a = false
	_will_attacked_by_attack_b = false
	_will_attacked_by_shoot = false


func _on_FlashCheckTimer_timeout():
	_enable_flash = false


func _on_FlashHardTimer_timeout():
	_flash_end = true


func _on_KillCheckTimer_timeout():
	_check_kill = true


func _on_HeartLessCheckTimer_timeout():
	_check_heart_less = true


func _on_FindArea_area_entered(area):
	var pl = area.get_parent() as Player
	if pl:
		player = pl


func _on_FindArea_area_exited(area):
	var pl = area.get_parent() as Player
	if pl:
		player = null


func _on_AttackArea_area_entered(area):
	var pl = area.get_parent() as Player
	if pl:
		_can_attack_player = true


func _on_AttackArea_area_exited(area):
	var pl = area.get_parent() as Player
	if pl:
		_can_attack_player = false


func _on_Animation_frame_changed():
	match $Animation.animation:
		"attack_a":
			if $Animation.frame == 0:
				_make_attack_a()


func _on_AttackArea_body_entered(body):
	_body_players.append(body)


func _on_AttackArea_body_exited(body):
	_body_players.remove(_body_players.find(body))
