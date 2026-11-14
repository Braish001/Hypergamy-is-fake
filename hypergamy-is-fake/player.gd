extends CharacterBody2D

@export var speed: float = 1200.0
@export var dash_speed: float = 3000.0      # Скорость во время рывка
@export var dash_duration: float = 0.2      # Длительность рывка в секундах
@export var dash_cooldown: float = 0.4      # Перезарядка рывка

# --- СИСТЕМА КОРТИЗОЛА ---
var cortisol: float = 0.0
var max_cortisol: float = 100.0
var decay_timer: float = 0.0

@export var cortisol_ui: TextureRect
@export var cortisol_label: Label
var cortisol_stages: Array[Texture2D] = []

# --- СИСТЕМА КРАСОТЫ (ВНЕШНОСТИ) ---
var beauty: float = 0.0
var max_beauty: float = 100.0
var beauty_decay_timer: float = 0.0       # Таймер потери 1 очка каждые 7.5 секунд

@export var beauty_ui: TextureRect          # ТекстурРайст для картинок рангов
var beauty_stages: Array[Texture2D] = []    # Массив картинок рангов

# Переменные для удара молотком
var is_hitting_self: bool = false
var hit_cooldown_timer: float = 0.0         # Строгий кулдаун 3 секунды
var current_hit_tween: Tween = null         # Переменная для контроля анимации удара

@export var hit_sound: AudioStream          # Файл звука удара
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var is_dashing: bool = false
var dash_time_left: float = 0.0
var cooldown_time_left: float = 0.0
var dash_direction: Vector2 = Vector2.DOWN

# --- СИСТЕМА ОРУЖИЯ В РУКАХ ---
@onready var held_item_sprite: Sprite2D = $HeldItemSprite
@export var weapon_textures: Array[Texture2D] = []

var current_weapon_slot: int = -1

# ==========================================
# ТОЧНАЯ НАСТРОЙКА ДЛЯ КАЖДОГО ИЗ 4 ПРЕДМЕТОВ:
# ==========================================

var weapon_scales: Array[Vector2] = [
	Vector2(0.32, 0.32),   # Слот 0 (Молоток)
	Vector2(0.37, 0.37),   # Слот 1 (Пистолет)
	Vector2(0.47, 0.47),   # Слот 2 (Дробовик)
	Vector2(0.2, 0.2)      # Слот 3 (Фотоальбом)
]

var weapon_offsets: Array[Vector2] = [
	Vector2(-45, 69),   # Слот 0 (Слева от персонажа)
	Vector2(43, 37),   # Слот 1 
	Vector2(43, 37),   # Слот 2 
	Vector2(43, 37)    # Слот 3 
]

var weapon_base_rotations: Array[float] = [
	-50,    # Слот 0 
	0.0,    # Слот 1 
	0.0,    # Слот 2 
	0.0     # Слот 3 
]

var weapon_flip_h: Array[bool] = [
	false,  # Слот 0
	true,   # Слот 1 
	true,   # Слот 2 
	false   # Слот 3
]


func _ready() -> void:
	var img = Image.load_from_file("res://sprites/cursor_game.png")
	img.resize(48, 48, Image.INTERPOLATE_BILINEAR)
	var scaled_cursor = ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(scaled_cursor, Input.CURSOR_ARROW, Vector2(16, 2.1))

	cortisol_stages = [
		load("res://sprites/low_cortisol.png"),             
		load("res://sprites/below_normal_cortisol.png"),    
		load("res://sprites/normal_cortisol.png"),          
		load("res://sprites/below_high_cortisol.png"),      
		load("res://sprites/high_cortisol.png")             
	]
	
	update_cortisol_display()
	update_beauty_display()
	
	if held_item_sprite != null:
		held_item_sprite.visible = false

func _physics_process(delta: float) -> void:
	# 1. Убывание кортизола (1 ед. за 60 секунд)
	if cortisol > 0:
		decay_timer += delta
		if decay_timer >= 60.0:
			decay_timer = 0.0
			cortisol = max(0.0, cortisol - 1.0)
			update_cortisol_display()

	# 2. Убывание красоты (1 очко каждые 7.5 секунд)
	if beauty > 0:
		beauty_decay_timer += delta
		if beauty_decay_timer >= 7.5:
			beauty_decay_timer = 0.0
			beauty = max(0.0, beauty - 1.0)
			update_beauty_display()

	# 3. Кулдаун удара молотком (уменьшается каждый кадр)
	if hit_cooldown_timer > 0:
		hit_cooldown_timer -= delta

	# 4. Таймер перезарядки рывка
	if cooldown_time_left > 0:
		cooldown_time_left -= delta

	# 5. Рывок по Пробелу
	if Input.is_action_just_pressed("ui_accept") and cooldown_time_left <= 0 and not is_dashing:
		var current_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		if current_dir != Vector2.ZERO:
			dash_direction = current_dir.normalized()
		else:
			dash_direction = Vector2.DOWN
			
		is_dashing = true
		dash_time_left = dash_duration
		cooldown_time_left = dash_cooldown
		
		cortisol = min(max_cortisol, cortisol + 1.0)
		update_cortisol_display()

	# 6. Логика движения
	if is_dashing:
		dash_time_left -= delta
		velocity = dash_direction * dash_speed
		
		if dash_time_left <= 0:
			is_dashing = false
	else:
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = direction * speed

	move_and_slide()

# Обработка клика ЛКМ для удара молотком
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_weapon_slot == 0 and not is_hitting_self and hit_cooldown_timer <= 0:
			start_self_hit()

func start_self_hit() -> void:
	is_hitting_self = true
	hit_cooldown_timer = 1.5  # Твое значение кулдауна
	print("Игрок бьет себя молотком по лицу!")
	
	# Звук удара комфортной громкости (0.4)
	if audio_stream_player != null:
		if hit_sound != null:
			audio_stream_player.stream = hit_sound
		audio_stream_player.volume_db = linear_to_db(0.4)
		audio_stream_player.play()
	
	# Анимация через Tween: плавно выпрямляем молоток в 0 градусов и возвращаем назад
	var offset = weapon_offsets[0]
	var base_rot = weapon_base_rotations[0]
	
	current_hit_tween = create_tween()
	current_hit_tween.set_parallel(false)
	
	# 1. Плавное движение в ровную позицию (0 градусов) — 0.25 сек
	current_hit_tween.tween_property(held_item_sprite, "rotation", deg_to_rad(0.0), 0.25)
	
	# Добавляем очко красоты в момент удара
	beauty = min(max_beauty, beauty + 1.0)
	update_beauty_display()
	print("Красота повышена: ", beauty)
	
	# 2. Плавный возврат в изначальную наклоненную точку (base_rot) — 0.35 сек
	current_hit_tween.tween_property(held_item_sprite, "rotation", deg_to_rad(base_rot), 0.35)
	
	# Снимаем блокировку по окончании анимации (0.25 + 0.35 = 0.6 сек)
	await get_tree().create_timer(0.6).timeout
	if current_weapon_slot == 0:
		is_hitting_self = false

# Поведение оружия каждый кадр
func _process(_delta: float) -> void:
	if held_item_sprite != null and held_item_sprite.visible and current_weapon_slot != -1:
		held_item_sprite.scale = weapon_scales[current_weapon_slot]
		var offset = weapon_offsets[current_weapon_slot]
		
		# --- СЛОТ 0: МОЛОТОК ---
		if current_weapon_slot == 0:
			if not is_hitting_self:
				held_item_sprite.position = offset
				held_item_sprite.rotation = deg_to_rad(weapon_base_rotations[0])
				held_item_sprite.flip_v = false
				held_item_sprite.flip_h = weapon_flip_h[0]
			
		# --- СЛОТЫ 1, 2, 3: ОРУЖИЕ (Смотрят на мышку) ---
		else:
			var mouse_pos = get_global_mouse_position()
			var dir = (mouse_pos - global_position).normalized()
			
			if global_position.distance_to(mouse_pos) < 5.0:
				dir = Vector2.RIGHT

			if mouse_pos.x < global_position.x:
				offset.x = -abs(offset.x)
				held_item_sprite.flip_v = true  
			else:
				offset.x = abs(offset.x)
				held_item_sprite.flip_v = false

			held_item_sprite.position = (dir * 10.0) + offset
			
			var target_angle = dir.angle() + deg_to_rad(weapon_base_rotations[current_weapon_slot])
			held_item_sprite.rotation = target_angle
			held_item_sprite.flip_h = weapon_flip_h[current_weapon_slot]

# Обновление UI кортизола
func update_cortisol_display() -> void:
	if cortisol_ui != null:
		var stage_index = int(cortisol / 20)
		stage_index = clamp(stage_index, 0, cortisol_stages.size() - 1)
		
		if cortisol_stages[stage_index] != null:
			cortisol_ui.texture = cortisol_stages[stage_index]
	
	if cortisol_label != null:
		cortisol_label.text = str(int(cortisol))

# Обновление UI красоты
func update_beauty_display() -> void:
	var stage_index = int(beauty / 25)
	stage_index = clamp(stage_index, 0, 3)
	
	var rank_names = ["Sub3", "LTN", "Chad", "True Adam"]
	print("Красота: ", beauty, " | Ранг: ", rank_names[stage_index])

# --- ФУНКЦИИ УПРАВЛЕНИЯ ОРУЖИЕМ В РУКАХ ---
func equip_weapon(slot_index: int) -> void:
	# Если меняем оружие во время удара — прерываем анимацию молотка
	if is_hitting_self:
		is_hitting_self = false
		if current_hit_tween and current_hit_tween.is_valid():
			current_hit_tween.kill()

	current_weapon_slot = slot_index
	
	if held_item_sprite == null:
		return
		
	if slot_index == -1:
		hide_held_weapon()
	else:
		if slot_index >= 0 and slot_index < weapon_textures.size():
			var tex = weapon_textures[slot_index]
			if tex != null:
				show_held_weapon(tex)

func show_held_weapon(new_texture: Texture2D) -> void:
	held_item_sprite.texture = new_texture
	held_item_sprite.visible = true
	held_item_sprite.self_modulate = Color(1, 1, 1, 1)

func hide_held_weapon() -> void:
	held_item_sprite.visible = false
