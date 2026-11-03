extends Camera2D

@export var max_offset: float = 200.0     # На какое максимальное расстояние в пикселях камера может сместиться от игрока
@export var smooth_speed: float = 5.0     # Скорость плавно движения камеры

func _process(delta: float) -> void:
	# Получаем размер экрана и позицию мыши внутри окна
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Вычисляем центр экрана
	var screen_center = viewport_size / 2.0
	
	# Находим вектор от центра экрана до мыши (нормализованный от -1 до 1)
	var mouse_direction = (mouse_pos - screen_center) / screen_center
	
	# Целевое смещение камеры в сторону мыши
	var target_offset = mouse_direction * max_offset
	
	# Плавно двигаем offset камеры к целевой позиции
	offset = offset.lerp(target_offset, smooth_speed * delta)
