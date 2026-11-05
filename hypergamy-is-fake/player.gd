extends CharacterBody2D

@export var speed: float = 1200
@export var dash_speed: float = 3000      # Скорость во время рывка
@export var dash_duration: float = 0.2     # Длительность рывка в секундах
@export var dash_cooldown: float = 4.0     # Перезарядка рывка (4 секунды)

var is_dashing: bool = false
var dash_time_left: float = 0.0
var cooldown_time_left: float = 0.0
var dash_direction: Vector2 = Vector2.DOWN

func _physics_process(delta: float) -> void:
	# Уменьшаем таймер перезарядки, если он активен
	if cooldown_time_left > 0:
		cooldown_time_left -= delta

	# Проверяем нажатие Пробела (действие "ui_accept" по умолчанию привязано к Пробелу)
	if Input.is_action_just_pressed("ui_accept") and cooldown_time_left <= 0 and not is_dashing:
		var current_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# Если игрок зажимает направление — рывок туда же. Если стоит — рывок вперед (вниз по умолчанию)
		if current_dir != Vector2.ZERO:
			dash_direction = current_dir.normalized()
		else:
			dash_direction = Vector2.DOWN
			
		is_dashing = true
		dash_time_left = dash_duration
		cooldown_time_left = dash_cooldown

	# Логика движения
	if is_dashing:
		# Пока идет рывок, летим с высокой скоростью в выбранном направлении
		dash_time_left -= delta
		velocity = dash_direction * dash_speed
		
		if dash_time_left <= 0:
			is_dashing = false
	else:
		# Обычное движение
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = direction * speed

	move_and_slide()


func _ready() -> void:
	# 1. Загружаем картинку как Image
	var img = Image.load_from_file("res://sprites/cursor_game.png")
	
	# 2. Изменяем размер прямо в памяти (например, до 32 на 32 пикселя)
	img.resize(48, 48, Image.INTERPOLATE_BILINEAR)
	
	# 3. Превращаем обратно в текстуру
	var scaled_cursor = ImageTexture.create_from_image(img)
	
	# 4. Устанавливаем как курсор с точкой клика на кончике (например, координаты 17, 2)
	Input.set_custom_mouse_cursor(scaled_cursor, Input.CURSOR_ARROW, Vector2(16, 2.1))
