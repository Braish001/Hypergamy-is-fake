extends Node2D

@onready var sector_polygon: Polygon2D = $SectorPolygon

@export var radius: float = 900               # Радиус зоны действия альбома
@export var duration: float = 0.7               # Показывается ровно 0.7 секунды
@export var sector_color: Color = Color(1.0, 0.15, 0.15, 0.35) # Полупрозрачный красный

var shooter: Node2D = null
var _timer: float = 0.0
var _aim_angle: float = 0.0
var _effect_triggered: bool = false

signal finished_range(triggered_any_npc: bool)

func setup(from_pos: Vector2, aim_world_pos: Vector2, owner_node: Node = null) -> void:
	shooter = owner_node as Node2D
	global_position = from_pos
	
	var dir = aim_world_pos - from_pos
	if dir.length() < 1.0:
		dir = Vector2.RIGHT
	_aim_angle = dir.angle()
	
	_build_third_circle_sector()
	_update_transform(from_pos)

func _build_third_circle_sector() -> void:
	if sector_polygon == null:
		return
	
	# 1/3 от полного круга (360 / 3 = 120 градусов)
	var arc_angle = TAU / 3.0
	var half_arc = arc_angle * 0.5
	var segments = 24
	
	var points = PackedVector2Array()
	points.append(Vector2.ZERO) # Центр сектора у игрока
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var angle = lerp(-half_arc, half_arc, t)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	sector_polygon.polygon = points
	sector_polygon.color = sector_color

func _update_transform(from_pos: Vector2) -> void:
	global_position = from_pos
	if shooter != null and shooter.is_inside_tree():
		var dir = shooter.get_global_mouse_position() - global_position
		if dir.length() >= 1.0:
			_aim_angle = dir.angle()
	rotation = _aim_angle

func _process(delta: float) -> void:
	_timer += delta
	
	if shooter != null and shooter.is_inside_tree():
		_update_transform(shooter.global_position)
	
	if _timer >= duration and not _effect_triggered:
		_effect_triggered = true
		var hit_npc = _check_npcs_in_sector()
		finished_range.emit(hit_npc)
		queue_free()

# ==========================================
# ЗАГОТОВКА НА БУДУЩЕЕ: ВЗАИМОДЕЙСТВИЕ С NPC В СЕКТОРЕ
# ==========================================
func _check_npcs_in_sector() -> bool:
	var any_npc_found = false
	var half_arc = (TAU / 3.0) * 0.5
	var forward_dir = Vector2.RIGHT.rotated(rotation)
	
	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return false
	
	var shape = CircleShape2D.new()
	shape.radius = radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	if shooter is CollisionObject2D:
		query.exclude = [shooter.get_rid()]
	
	var results = space_state.intersect_shape(query, 32)
	var processed_ids: Dictionary = {}
	
	for item in results:
		var collider = item.get("collider")
		var npc_node = _resolve_npc_node(collider)
		if npc_node == null:
			continue
		
		var npc_id = npc_node.get_instance_id()
		if processed_ids.has(npc_id):
			continue
		
		var to_npc = (npc_node as Node2D).global_position - global_position if npc_node is Node2D else Vector2.ZERO
		if to_npc.length() <= radius:
			var angle_diff = abs(forward_dir.angle_to(to_npc.normalized()))
			if angle_diff <= half_arc:
				processed_ids[npc_id] = true
				any_npc_found = true
				_handle_npc_in_album_range(npc_node)
	
	return any_npc_found

func _resolve_npc_node(collider: Object) -> Node:
	if collider == null:
		return null
	if collider is Node:
		var node := collider as Node
		if node.has_method("apply_album_effect") or node.is_in_group("npc"):
			return node
		var parent = node.get_parent()
		if parent != null and (parent.has_method("apply_album_effect") or parent.is_in_group("npc")):
			return parent
	return null

func _handle_npc_in_album_range(npc_node: Node) -> void:
	if npc_node.has_method("apply_album_effect"):
		npc_node.apply_album_effect(shooter)
	# Здесь позже добавишь реакцию NPC на показ фотоальбома
	print("NPC попал в зону альбома: ", npc_node.name)
