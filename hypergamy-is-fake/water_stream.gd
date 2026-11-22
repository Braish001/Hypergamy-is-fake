extends Node2D

@onready var line: Line2D = $StreamLine

@export var max_range: float = 450.0 # Максимальная дальность струи водяного пистолета
@export var lifetime: float = 0.14
@export var water_amount: float = 10.0

var shooter: Node2D = null
var muzzle_local_offset: Vector2 = Vector2(28.0, 0.0) # Чуть правее центра пистолета (дуло)
var target_world_pos: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _hit_processed: bool = false

func setup(from_pos: Vector2, aim_world_pos: Vector2, owner_node: Node = null, muzzle_offset: Vector2 = Vector2(28.0, 0.0)) -> void:
	shooter = owner_node as Node2D
	muzzle_local_offset = muzzle_offset
	_update_stream(from_pos, aim_world_pos)

func _get_current_muzzle_pos(fallback_pos: Vector2) -> Vector2:
	if shooter != null and shooter.is_inside_tree():
		var sprite = shooter.get_node_or_null("HeldItemSprite") as Node2D
		if sprite != null and sprite.visible:
			# Берем точку чуть правее/вперед от центра пистолета с учетом его поворота и масштаба
			var local_tip = muzzle_local_offset
			# Если спрайт развернут по вертикали при прицеливании влево, корректируем Y
			if sprite is Sprite2D and sprite.flip_v:
				local_tip.y = -local_tip.y
			return sprite.to_global(local_tip)
		return shooter.global_position + muzzle_local_offset
	return fallback_pos

func _clamp_aim_to_range(from_pos: Vector2, aim_world_pos: Vector2) -> Vector2:
	var to_aim = aim_world_pos - from_pos
	var dist = to_aim.length()
	if dist < 1.0:
		return from_pos + Vector2.RIGHT * max_range
	if dist > max_range:
		return from_pos + (to_aim / dist) * max_range
	return aim_world_pos

func _update_stream(from_pos: Vector2, aim_world_pos: Vector2) -> void:
	global_position = from_pos
	var end_pos: Vector2 = _clamp_aim_to_range(from_pos, aim_world_pos)

	var space_state = get_world_2d().direct_space_state
	if space_state != null and from_pos.distance_to(end_pos) > 1.0:
		var query = PhysicsRayQueryParameters2D.create(from_pos, end_pos)
		if shooter is CollisionObject2D:
			query.exclude = [shooter.get_rid()]

		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			end_pos = result.position
			var hit_collider = result.collider
			_on_hit_target(hit_collider, result.position, result.normal)

	target_world_pos = end_pos
	line.points = PackedVector2Array([Vector2.ZERO, to_local(end_pos)])

func _process(delta: float) -> void:
	_timer += delta
	var t = clamp(_timer / lifetime, 0.0, 1.0)

	# Если игрок идет — пересчитываем начало и конец струи, чтобы она "гонялась" за ним
	if shooter != null and shooter.is_inside_tree():
		var current_start = _get_current_muzzle_pos(global_position)
		var current_aim = shooter.get_global_mouse_position()
		_update_stream(current_start, current_aim)

	# Плавное затухание струи
	modulate.a = 1.0 - t

	if _timer >= lifetime:
		queue_free()

# ==========================================
# ЗАГОТОВКА НА БУДУЩЕЕ: ВЗАИМОДЕЙСТВИЕ С NPC
# ==========================================
func _on_hit_target(collider: Object, hit_pos: Vector2, hit_normal: Vector2) -> void:
	if _hit_processed or collider == null:
		return
	_hit_processed = true

	# 1. Если у NPC/объекта есть метод реакции на воду — вызываем его
	if collider.has_method("apply_water_effect"):
		collider.apply_water_effect(water_amount, hit_pos, hit_normal, shooter)

	# 2. Или если объект/NPC в группе "npc" — можно обработать отдельно
	elif collider is Node and collider.is_in_group("npc"):
		_handle_npc_hit(collider, hit_pos, hit_normal)

func _handle_npc_hit(npc_node: Node, hit_pos: Vector2, _hit_normal: Vector2) -> void:
	# Здесь позже добавишь логику изменения состояния NPC после попадания воды:
	# намокание, смену спрайта/анимации, реакцию кортизола/красоты или поведение NPC
	print("Попадание воды по NPC: ", npc_node.name, " в точке ", hit_pos)
