extends Node2D

@onready var lines_container: Node2D = $LinesContainer
@onready var muzzle_flash: CanvasItem = $MuzzleFlash

@export var pellet_count: int = 9              # 8-9 дробинок/линий
@export var max_range: float = 1480           # Увеличено в ~1.5 раза (было 620.0)
@export var spread_degrees: float = 54.0       # Широкий разброс вверх/вниз по вееру
@export var blast_lifetime: float = 0.24       # Длительность отображения линий и точек
@export var flash_duration: float = 0.1        # Свечение у дула 0.1 секунды
@export var pellet_damage_or_power: float = 1.0

var shooter: Node2D = null
var muzzle_local_offset: Vector2 = Vector2(36.0, 0.0)
var _timer: float = 0.0
var _aim_angle: float = 0.0
var _pellet_angles: Array[float] = []
var _pellet_length_mults: Array[float] = []
var _hit_npc_once: Dictionary = {}

func setup(from_pos: Vector2, aim_world_pos: Vector2, owner_node: Node = null, muzzle_offset: Vector2 = Vector2(36.0, 0.0)) -> void:
	shooter = owner_node as Node2D
	muzzle_local_offset = muzzle_offset
	
	_pellet_angles.clear()
	_pellet_length_mults.clear()
	_hit_npc_once.clear()
	
	var base_dir = aim_world_pos - from_pos
	if base_dir.length() < 1.0:
		base_dir = Vector2.RIGHT
	_aim_angle = base_dir.angle()
	
	var count = clamp(pellet_count, 8, 9)
	for i in range(count):
		var t = 0.0 if count == 1 else float(i) / float(count - 1)
		# Широкий веер от -spread_degrees/2 до +spread_degrees/2 + случайный разброс по углам
		var fan_deg = lerp(-spread_degrees * 0.5, spread_degrees * 0.5, t)
		var extra_spread_deg = randf_range(-8.0, 8.0)
		_pellet_angles.append(_aim_angle + deg_to_rad(fan_deg + extra_spread_deg))
		
		# Разная длина у каждой пульки: некоторые короче, некоторые длиннее
		_pellet_length_mults.append(randf_range(0.45, 1.0))
	
	_rebuild_pellets(from_pos)
	_sync_muzzle_flash()

func _sync_muzzle_flash() -> void:
	if muzzle_flash != null:
		if muzzle_flash is Node2D:
			(muzzle_flash as Node2D).position = Vector2.ZERO
			(muzzle_flash as Node2D).rotation = _aim_angle
		elif muzzle_flash is Control:
			(muzzle_flash as Control).position = Vector2.ZERO
		muzzle_flash.visible = true
		muzzle_flash.modulate.a = 1.0

func _get_current_muzzle_pos(fallback_pos: Vector2) -> Vector2:
	if shooter != null and shooter.is_inside_tree():
		var sprite = shooter.get_node_or_null("HeldItemSprite") as Node2D
		if sprite != null and sprite.visible:
			var local_tip = muzzle_local_offset
			if sprite is Sprite2D and sprite.flip_v:
				local_tip.y = -local_tip.y
			return sprite.to_global(local_tip)
		return shooter.global_position + muzzle_local_offset
	return fallback_pos

func _rebuild_pellets(start_pos: Vector2) -> void:
	global_position = start_pos
	
	for child in lines_container.get_children():
		child.queue_free()
	
	var space_state = get_world_2d().direct_space_state
	
	for i in range(_pellet_angles.size()):
		var angle = _pellet_angles[i]
		var length_mult = _pellet_length_mults[i]
		var dir = Vector2.RIGHT.rotated(angle)
		var end_pos = start_pos + dir * (max_range * length_mult)
		
		if space_state != null:
			# Проверяем всех врагов/NPC вдоль всей длины пульки (не только на конце и не останавливаясь на первом враге)
			_check_crowd_along_pellet(space_state, start_pos, end_pos)
			
			# Если есть стена/препятствие (не NPC) — ограничиваем длину этой пульки стеной
			var wall_pos = _get_wall_stop_pos(space_state, start_pos, end_pos)
			if wall_pos != Vector2.INF:
				end_pos = wall_pos
		
		var local_end = to_local(end_pos)
		
		# Линия дробинки
		var line = Line2D.new()
		line.points = PackedVector2Array([Vector2.ZERO, local_end])
		line.width = 6.0
		line.default_color = Color(1.0, 0.92, 0.65, 0.95)
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		lines_container.add_child(line)
		
		# Точка на конце дробинки
		var tip_dot = _create_tip_dot(local_end)
		lines_container.add_child(tip_dot)

func _check_crowd_along_pellet(space_state: PhysicsDirectSpaceState2D, from_pos: Vector2, to_pos: Vector2) -> void:
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var exclude_rids: Array[RID] = []
	if shooter is CollisionObject2D:
		exclude_rids.append(shooter.get_rid())
	
	# Идем по лучу, собирая всех задетых NPC вдоль всей длины пульки
	for _step in range(16):
		query.exclude = exclude_rids
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			break
		
		var collider = result.collider
		var hit_pos: Vector2 = result.position
		var hit_normal: Vector2 = result.normal
		
		if collider is CollisionObject2D:
			exclude_rids.append((collider as CollisionObject2D).get_rid())
		
		var target_node = _resolve_npc_node(collider)
		if target_node != null:
			_on_pellet_hit(target_node, hit_pos, hit_normal)
		else:
			# Встретили не-NPC (например, стену/препятствие) — дальше эта дробь не проходит
			break

func _get_wall_stop_pos(space_state: PhysicsDirectSpaceState2D, from_pos: Vector2, to_pos: Vector2) -> Vector2:
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var exclude_rids: Array[RID] = []
	if shooter is CollisionObject2D:
		exclude_rids.append(shooter.get_rid())
	
	for _step in range(16):
		query.exclude = exclude_rids
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return Vector2.INF
		
		var collider = result.collider
		if _resolve_npc_node(collider) != null:
			if collider is CollisionObject2D:
				exclude_rids.append((collider as CollisionObject2D).get_rid())
			continue
		
		return result.position
	
	return Vector2.INF

func _resolve_npc_node(collider: Object) -> Node:
	if collider == null:
		return null
	if collider is Node:
		var node := collider as Node
		if node.has_method("apply_shotgun_effect") or node.is_in_group("npc"):
			return node
		var parent = node.get_parent()
		if parent != null and (parent.has_method("apply_shotgun_effect") or parent.is_in_group("npc")):
			return parent
	return null

func _create_tip_dot(local_pos: Vector2) -> Polygon2D:
	var dot = Polygon2D.new()
	var pts = PackedVector2Array()
	var radius = 8.0
	var segments = 8
	for s in range(segments):
		var a = (TAU / segments) * s
		pts.append(Vector2(cos(a), sin(a)) * radius)
	dot.polygon = pts
	dot.position = local_pos
	dot.color = Color(1.0, 0.75, 0.25, 1.0)
	return dot

func _process(delta: float) -> void:
	_timer += delta
	
	if shooter != null and shooter.is_inside_tree():
		var current_start = _get_current_muzzle_pos(global_position)
		_rebuild_pellets(current_start)
	
	if muzzle_flash != null:
		if muzzle_flash is Node2D:
			(muzzle_flash as Node2D).position = Vector2.ZERO
			(muzzle_flash as Node2D).rotation = _aim_angle
		if _timer <= flash_duration:
			muzzle_flash.visible = true
			muzzle_flash.modulate.a = 1.0 - (_timer / flash_duration)
		else:
			muzzle_flash.visible = false
	
	var fade_t = clamp(_timer / blast_lifetime, 0.0, 1.0)
	lines_container.modulate.a = 1.0 - fade_t
	
	if _timer >= blast_lifetime:
		queue_free()

# ==========================================
# ЗАГОТОВКА НА БУДУЩЕЕ: ВЗАИМОДЕЙСТВИЕ С NPC
# ==========================================
func _on_pellet_hit(npc_node: Node, hit_pos: Vector2, hit_normal: Vector2) -> void:
	if npc_node == null:
		return
	
	if npc_node.has_method("apply_shotgun_effect"):
		npc_node.apply_shotgun_effect(pellet_damage_or_power, hit_pos, hit_normal, shooter)
	
	var npc_id = npc_node.get_instance_id()
	if not _hit_npc_once.has(npc_id):
		_hit_npc_once[npc_id] = true
		_handle_npc_hit(npc_node, hit_pos, hit_normal)

func _handle_npc_hit(npc_node: Node, hit_pos: Vector2, _hit_normal: Vector2) -> void:
	# Здесь позже добавишь логику изменения состояния/уничтожения толп NPC после попадания дробовика
	print("Дробовик задел NPC: ", npc_node.name, " в точке ", hit_pos)
