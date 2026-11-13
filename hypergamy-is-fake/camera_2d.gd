extends Camera2D

@export var max_offset: float = 200.0      # Максимальное смещение за мышкой
@export var smooth_speed: float = 5.0      # Скорость движения за мышкой

@export var zoom_min: float = 0.2         # Сделали еще меньше, теперь можно отдалить намного сильнее!
@export var zoom_max: float = 2.0          # Максимальное приближение
@export var zoom_speed: float = 0.1        # Скорость зума
@export var zoom_smooth: float = 10.0      # Плавность зума

var target_zoom: Vector2 = Vector2(1, 1)

func _ready() -> void:
	target_zoom = zoom

func _unhandled_input(event: InputEvent) -> void:
	# Обрабатываем прокрутку колесика мыши для зума
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Колесико вверх -> приближаем
			target_zoom += Vector2(zoom_speed, zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Колесико вниз -> отдаляем
			target_zoom -= Vector2(zoom_speed, zoom_speed)
		
		# Ограничиваем минимальное и максимальное значение зума
		target_zoom.x = clamp(target_zoom.x, zoom_min, zoom_max)
		target_zoom.y = clamp(target_zoom.y, zoom_min, zoom_max)

func _process(delta: float) -> void:
	# 1. Подсмотр за мышкой по краям экрана
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	var screen_center = viewport_size / 2.0
	var mouse_direction = (mouse_pos - screen_center) / screen_center
	var target_offset = mouse_direction * max_offset
	
	offset = offset.lerp(target_offset, smooth_speed * delta)

	# 2. Плавное изменение зума
	zoom = zoom.lerp(target_zoom, zoom_smooth * delta)
