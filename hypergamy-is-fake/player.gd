extends CharacterBody2D

@export var speed: float = 1200.0
@export var dash_speed: float = 3000.0      # Скорость во время рывка
@export var dash_duration: float = 0.2      # Длительность рывка в секундах
@export var dash_cooldown: float = 0.4      # Перезарядка рывка (4 секунды)

# Система кортизола
var cortisol: float = 0.0
var max_cortisol: float = 100.0
var decay_timer: float = 0.0

# Перетащи TextureRect и Label сюда прямо из дерева сцены через Инспектор!
@export var cortisol_ui: TextureRect
@export var cortisol_label: Label

# Массив спрайтов кортизола (в строгом правильном порядке)
var cortisol_stages: Array[Texture2D] = []

var is_dashing: bool = false
var dash_time_left: float = 0.0
var cooldown_time_left: float = 0.0
var dash_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	# 1. Загружаем картинку курсора
	var img = Image.load_from_file("res://sprites/cursor_game.png")
	img.resize(48, 48, Image.INTERPOLATE_BILINEAR)
	var scaled_cursor = ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(scaled_cursor, Input.CURSOR_ARROW, Vector2(16, 2.1))

	# 2. Правильный порядок шкал кортизола:
	cortisol_stages = [
		load("res://sprites/low_cortisol.png"),             # 0-19: Low
		load("res://sprites/below_normal_cortisol.png"),    # 20-39: Below Normal
		load("res://sprites/normal_cortisol.png"),          # 40-59: Normal
		load("res://sprites/below_high_cortisol.png"),      # 60-79: Below High
		load("res://sprites/high_cortisol.png")             # 80-100: High
	]
	
	update_cortisol_display()

func _physics_process(delta: float) -> void:
	# 1. Убывание 1 единицы кортизола раз в 1 минуту (60 секунд)
	if cortisol > 0:
		decay_timer += delta
		if decay_timer >= 60.0:
			decay_timer = 0.0
			cortisol = max(0.0, cortisol - 1.0)
			update_cortisol_display()

	# 2. Таймер перезарядки рывка
	if cooldown_time_left > 0:
		cooldown_time_left -= delta

	# 3. Рывок по Пробелу
	if Input.is_action_just_pressed("ui_accept") and cooldown_time_left <= 0 and not is_dashing:
		var current_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		if current_dir != Vector2.ZERO:
			dash_direction = current_dir.normalized()
		else:
			dash_direction = Vector2.DOWN
			
		is_dashing = true
		dash_time_left = dash_duration
		cooldown_time_left = dash_cooldown
		
		# Увеличиваем кортизол на 1 за каждый деш (максимум 100)
		cortisol = min(max_cortisol, cortisol + 1.0)
		update_cortisol_display()
		print("Кортизол: ", cortisol)

	# 4. Логика движения
	if is_dashing:
		dash_time_left -= delta
		velocity = dash_direction * dash_speed
		
		if dash_time_left <= 0:
			is_dashing = false
	else:
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = direction * speed

	move_and_slide()

# Функция обновления картинки и текста кортизола в UI
func update_cortisol_display() -> void:
	# Обновляем картинку шкалы
	if cortisol_ui != null:
		var stage_index = int(cortisol / 20)
		stage_index = clamp(stage_index, 0, cortisol_stages.size() - 1)
		
		if cortisol_stages[stage_index] != null:
			cortisol_ui.texture = cortisol_stages[stage_index]
	
	# Обновляем текст с числовым значением
	if cortisol_label != null:
		cortisol_label.text = str(int(cortisol))
