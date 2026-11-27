extends CharacterBody2D

@export var speed: float = 300.0
var move_direction: Vector2 = Vector2.ZERO

@onready var timer: Timer = $Timer

func _ready() -> void:
	# Подключаем таймер к функции смены направления
	timer.timeout.connect(_pick_new_direction)
	_pick_new_direction() # Сразу выбираем первое направление при старте

func _physics_process(_delta: float) -> void:
	velocity = move_direction * speed
	move_and_slide()
	
	# Если NPC уперся в стену или игрока — сразу меняем направление, чтобы не буксовал
	if is_on_wall():
		_pick_new_direction()

func _pick_new_direction() -> void:
	# С вероятностью 30% NPC просто постоит на месте, иначе пойдет в случайную сторону
	if randf() < 0.3:
		move_direction = Vector2.ZERO
	else:
		# Выбираем случайный угол от 0 до 360 градусов
		var random_angle = randf_range(0, TAU)
		move_direction = Vector2.RIGHT.rotated(random_angle)
