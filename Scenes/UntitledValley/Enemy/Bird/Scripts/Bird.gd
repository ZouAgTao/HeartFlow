extends KinematicBody2D

const FLY_SPEED = 100
const ATTACK_SPEED = 800
const ATTACKED_X_SPEED = 250

export(int) var attack_damage = 2
export(int) var life_num = 4
export(int) var CEIL_Y = 150

var _motion : Vector2 = Vector2()

var player : Player = null
var can_attack : bool = false

var _life_num : int = 4

var attack_forward : Vector2 = Vector2()
var _is_attacking : bool = false
var _is_face_to_right : bool = false
var _attack_success : bool = false
var _is_attacked : bool = false
var _attacked_to_right : bool = true

var _is_dead : bool = false

enum ATTACKED_TYPE {
	ATTACK_A,
	ATTACK_B,
	SHOOT
}

var attack_type = ATTACKED_TYPE.ATTACK_A

func trigger_attacked_by_attacked_a(is_attack_forward_to_right : bool, damage : int) -> bool:
	# 由damage处理伤害的计算
	_make_damage(damage)
	
	# attack_forward产生方向性的attacked的趋势
	_is_attacking = false
	_is_attacked = true
	attack_type = ATTACKED_TYPE.ATTACK_A
	_attacked_to_right = is_attack_forward_to_right
	
	$AttackedHardTimer.stop()
	$AttackedHardTimer.start()
	
	return true


func trigger_attacked_by_attacked_b(is_attack_forward_to_right : bool, damage : int) -> bool:
	# 由damage处理伤害的计算
	_make_damage(damage)
	
	# attack_forward产生方向性的attacked的趋势
	_is_attacking = false
	_is_attacked = true
	attack_type = ATTACKED_TYPE.ATTACK_B
	_attacked_to_right = is_attack_forward_to_right
	
	$AttackedHardTimer.stop()
	$AttackedHardTimer.start()
	
	return true


func trigger_attacked_by_shoot(is_attack_forward_to_right : bool, damage : int) -> bool:
	# 由damage处理伤害的计算
	_make_damage(damage)
	
	# attack_forward产生方向性的attacked的趋势
	_is_attacking = false
	_is_attacked = true
	attack_type = ATTACKED_TYPE.SHOOT
	_attacked_to_right = is_attack_forward_to_right
	
	$AttackedHardTimer.stop()
	$AttackedHardTimer.start()
	
	return true


func _ready():
	$Animation.play()
	$Animation.animation = "idle"
	
	_life_num = life_num


func _process(delta):
	_motion.x = 0
	
	
	if _is_dead:
		_motion.y += 19.6
		$Animation.animation = "die"
		return
	else:
		_motion.y = 0
	
	if player:
		if _is_attacked:
			$Animation.animation = "attacked"
			$Animation.flip_h = not _attacked_to_right
			
			if attack_type == ATTACKED_TYPE.SHOOT or attack_type == ATTACKED_TYPE.ATTACK_B:
				if _attacked_to_right:
					_motion.x = ATTACKED_X_SPEED
				else:
					_motion.x = -ATTACKED_X_SPEED
			
			return
		
		if self.is_on_floor() or self.is_on_wall():
			_is_attacking = false
		
		if self.is_on_ceiling():
			if not can_attack:
				can_attack = true
		
		if _attack_success:
			_attack_success = false
			_is_attacking = false
		
		if _is_attacking:
			$Animation.animation = "attack_a"
			_motion = attack_forward * ATTACK_SPEED
			return
		
		_is_face_to_right = player.position.x > self.position.x
		$Animation.animation = "move"
		$Animation.flip_h = _is_face_to_right
		
		if can_attack:
			attack_forward = (player.position - self.position).normalized()
			_is_attacking = true
			can_attack = false
			
		else:
			if position.y > CEIL_Y:
				_motion.y = -FLY_SPEED
			else:
				can_attack = true

	else:
		$Animation.animation = "idle"


func _make_damage(damage : int) -> void:
	_life_num -= damage
	
	if _life_num <= 0:
		_life_num = 0
		
		_make_die()


func _make_die() -> void:
	_is_dead = true
	
	var parent = self.get_parent()
	if parent.has_method("enemy_die"):
		parent.enemy_die()
	
	_become_dead_body()


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


func _physics_process(delta):
	_motion = move_and_slide(_motion, Vector2.UP)


func _on_FindArea_area_entered(area : Area2D):
	var area_player = area.get_parent() as Player
	if area_player:
		player = area_player


func _on_AttackArea_area_entered(area):
	if _is_attacking:
		var area_player = area.get_parent() as Player
		if area_player:
			_is_attacking = false
			if area_player.has_method("trigger_attacked_by_attacked_b"):
				area_player.trigger_attacked_by_attacked_b(_is_face_to_right ,attack_damage)


func _on_AttackedHardTimer_timeout():
	_is_attacked = false
