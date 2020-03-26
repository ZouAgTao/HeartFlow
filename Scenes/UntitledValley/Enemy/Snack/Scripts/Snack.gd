extends KinematicBody2D

export(PackedScene) var duye
export(bool) var is_face_to_right = false
export(int) var life_num = 5

var _player : Player = null

var can_attack : bool = true
var is_attacked : bool = false
var is_dead : bool = false
var can_attacked : bool = false


func trigger_attacked_by_attacked_a(is_attack_forward_to_right : bool, damage : int) -> bool:
	_make_damage(damage)
	
	_attacked()
	
	return true


func trigger_attacked_by_attacked_b(is_attack_forward_to_right : bool, damage : int) -> bool:
	_make_damage(damage)
	
	_attacked()
	
	return true


func trigger_attacked_by_shoot(is_attack_forward_to_right : bool, damage : int) -> bool:
	_make_damage(damage)
	
	_attacked()
	
	return true


func _make_die() -> void:
	if not is_dead:
		is_dead = true
		
		_become_dead_body()
		var parent = self.get_parent()
		if parent.has_method("enemy_die"):
			parent.enemy_die()


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


func _attacked() -> void:
	if not is_attacked:
		is_attacked = true
		can_attacked = true


func _make_damage(damage : int) -> void:
	if life_num > 0:
		life_num -= damage
		if life_num <= 0:
			life_num = 0
			_make_die()


func _attack_by_shoot_duye() -> void:
	if duye:
		var duye_inst = duye.instance()
		self.get_parent().add_child(duye_inst)
		if duye_inst.has_method("fly"):
			duye_inst.fly(self.position, _player.position)


func _ready():
	$Animation.play()
	$Animation.flip_h = is_face_to_right


func _process(delta):
	if is_dead:
		$Animation.animation = "die"
		return
	
	if is_attacked:
		$Animation.animation = "attacked"
		if can_attacked:
			can_attacked = false
			$AttackedHardTimer.start()
		
		return
	
	
	if _player:
		is_face_to_right = _player.position.x > self.position.x
		$Animation.flip_h = is_face_to_right
		
		if can_attack:
			$Animation.animation = "attack_a"
			_attack_by_shoot_duye()
			can_attack = false
			$AttackHardTimer.start()
			$AttackNepTimer.start()
		
	else:
		$Animation.animation = "idle"


func _on_AttackArea_body_entered(body):
	var player_body = body as Player
	
	if player_body:
		_player = player_body
		can_attack = true


func _on_AttackArea_body_exited(body):
	var player_body = body as Player
	
	if player_body:
		_player = null
		can_attack = false


func _on_AttackHardTimer_timeout():
	$Animation.animation = "idle"


func _on_AttackNepTimer_timeout():
	can_attack = true


func _on_AttackedHardTimer_timeout():
	is_attacked = false
