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

# --- СТРЕЛЬБА: ВОДЯНОЙ ПИСТОЛЕТ (СЛОТ 1) ---
@export var water_stream_scene: PackedScene
@export var water_fire_cooldown: float = 0.08       # Частота выплеска при зажатии ЛКМ
@export var water_muzzle_offset: Vector2 = Vector2(203.0, -31.0) # Смещение вправо от центра пистолета
var water_cooldown_timer: float = 0.0

# Вода (100/100L): при зажатии стрельбы тратится 1 литр раз в 5 секунд
@export var max_water_liters: float = 100.0
@export var water_hold_drain_interval: float = 5.0
var water_liters: float = 100.0
var water_hold_drain_timer: float = 0.0

@export var water_hud: CanvasItem
@export var water_amount_label: Label

# --- СТРЕЛЬБА: ДРОБОВИК (СЛОТ 2) ---
@export var shotgun_blast_scene: PackedScene
@export var shotgun_fire_cooldown: float = 0.45
@export var shotgun_muzzle_offset: Vector2 = Vector2(300.0, -37.0)
@export var max_shotgun_ammo: int = 2               # Максимум 2 патрона в дробовике
@export var max_reserve_shotgun_ammo: int = 2       # Максимум 2 патрона можно хранить у себя в запасе
@export var shotgun_reload_duration: float = 0.7    # Длительность зарядки 1 патрона (увеличено в 2 раза)

@export_group("Shotgun Cursor")
@export var shotgun_cursor_texture: Texture2D               # Картинка курсора при взятии дробовика
@export var shotgun_cursor_size: Vector2i = Vector2i(48, 48) # Размер курсора дробовика в пикселях
@export var shotgun_cursor_hotspot: Vector2 = Vector2(24.0, 24.0) # Точка привязки (центр прицела) курсора
@export_group("")

@export_group("Shotgun Reload Animation")
@export var shotgun_reload_texture: Texture2D                  # Картинка для анимации перезарядки 1 патрона
@export var shotgun_reload_scale: Vector2 = Vector2(0.47, 0.47) # Масштаб картинки перезарядки
@export var shotgun_reload_offset: Vector2 = Vector2(43, 25)  # Смещение картинки перезарядки относительно игрока
@export var shotgun_reload_rotation: float = -22.0            # Базовый наклон в градусах во время зарядки
@export var shotgun_reload_flip_h: bool = true                # Горизонтальный отзеркаливание картинки перезарядки
@export var shotgun_reload_kick: Vector2 = Vector2(-10.0, -14.0) # Короткий ход картинки во время зарядки
@export_group("")

var shotgun_ammo_in_mag: int = 0                    # Изначально 0 патронов в дробовике
var reserve_shotgun_ammo: int = 0                   # Подобранные с карты патроны (до 2 штук у себя)
var shotgun_cooldown_timer: float = 0.0
var shotgun_reload_timer: float = 0.0
var is_reloading_shotgun: bool = false
var _reload_anim_offset: Vector2 = Vector2.ZERO
var _reload_anim_rot_deg: float = 0.0
var _current_reload_tween: Tween = null

var _default_cursor_texture: Texture2D = null
var _default_cursor_hotspot: Vector2 = Vector2(21.0, 15.0)
var _shotgun_scaled_cursor: Texture2D = null
var _last_cursor_sig: String = ""

@export var shotgun_shot_sound: AudioStream          # Краткий звук выстрела
@export var shotgun_shot_volume_db: float = -8.0     # Приглушение громкого выстрела
@export var ringing_sound: AudioStream               # Звон в ушах
@export var ringing_duration: float = 5.5            # Длительность затухания (5-6 сек)
@export var ringing_start_db: float = -6.0           # Громкость звона в момент выстрела
@export var ringing_min_db: float = -45.0          # Почти тишина к концу затухания
@export var camera_shake_strength: float = 100       # Заметная тряска экрана (в пикселях)
@export var camera_shake_duration: float = 0.18      # Длительность тряски

@onready var shotgun_shot_player: AudioStreamPlayer = $ShotgunShotPlayer
@onready var ringing_player: AudioStreamPlayer = $RingingPlayer

var _active_ringings: Array[Dictionary] = []
var _shake_timer: float = 0.0
var _last_shake_jitter: Vector2 = Vector2.ZERO
var _active_camera: Camera2D = null

@export var shotgun_hud: CanvasItem
@export var shotgun_ammo_label: Label
@export var shotgun_reserve_label: Label

# --- ФОТОАЛЬБОМ (СЛОТ 3) ---
@export var album_range_scene: PackedScene
@export var album_flash_ui: TextureRect             # Полноэкранная фотка-вспышка на весь экран
@export var album_range_duration: float = 0.7       # Красный сектор 1/3 круга — 0.7 сек
@export var album_flash_duration: float = 0.6       # Плавное исчезновение флешки — 0.6 сек
@export var album_meme_sound: AudioStream           # Звук при появлении фотки
@export var album_meme_sound_volume_db: float = 0.0 # Громкость звука появления фотки
@export var album_meme_sound_start_at: float = 1.5  # С какой секунды внутри файла стартовать звук
@export var album_meme_sound_duration: float = 0.0  # Сколько сек играть звук после старта (0.0 = до конца)
@export var album_cooldown_duration: float = 12.0   # Отсчёт с 12 секунд после нажатия
@onready var album_meme_player: AudioStreamPlayer = get_node_or_null("AlbumMemePlayer")
var album_memes: Array[Texture2D] = []
var is_album_active: bool = false
var _meme_sound_timer: float = 0.0
var _meme_sound_total_duration: float = 0.0
var _flash_timer: float = 0.0
var _flash_start_modulate: Color = Color(1.35, 1.35, 1.35, 0.9)
var album_cooldown_left: float = 0.0
var _last_shown_countdown: int = -1

@export var album_hud: CanvasItem
@export var album_status_label: Label

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
	Vector2(0.37, 0.37),   # Слот 1 (Водяной пистолет)
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
	randomize()
	water_liters = max_water_liters
	water_hold_drain_timer = 0.0
	shotgun_ammo_in_mag = 0
	reserve_shotgun_ammo = 0
	shotgun_reload_timer = 0.0
	is_reloading_shotgun = false
	_reload_anim_offset = Vector2.ZERO
	_reload_anim_rot_deg = 0.0
	album_cooldown_left = 0.0

	var img = Image.load_from_file("res://sprites/cursor_game.png")
	img.resize(48, 48, Image.INTERPOLATE_BILINEAR)
	_default_cursor_texture = ImageTexture.create_from_image(img)
	_apply_cursor_for_slot(current_weapon_slot, true)

	cortisol_stages = [
		load("res://sprites/low_cortisol.png"),             
		load("res://sprites/below_normal_cortisol.png"),    
		load("res://sprites/normal_cortisol.png"),          
		load("res://sprites/below_high_cortisol.png"),      
		load("res://sprites/high_cortisol.png")             
	]

	beauty_stages = [
		load("res://sprites/sub_look.png"),
		load("res://sprites/ltn_look.png"),
		load("res://sprites/chad_look.png"),
		load("res://sprites/adam_look.png")
	]

	album_memes = [
		load("res://sprites/photo_1.png"),
		load("res://sprites/photo_2.jpg"),
		load("res://sprites/photo_3.jpeg"),
		load("res://sprites/photo_4.png"),
		load("res://sprites/photo_5.png"),
		load("res://sprites/photo_6.jpg"),
		load("res://sprites/photo_7.jpg"),
		load("res://sprites/photo_8.png"),
		load("res://sprites/photo_9.png")
	]

	if album_flash_ui != null:
		_flash_start_modulate = album_flash_ui.modulate
		if _flash_start_modulate.a <= 0.01:
			_flash_start_modulate = Color(1.35, 1.35, 1.35, 0.9)
		album_flash_ui.visible = false
	
	update_cortisol_display()
	update_beauty_display()
	update_weapon_hud_visibility()
	update_water_hud()
	update_shotgun_hud()
	update_album_hud()
	
	if held_item_sprite != null:
		held_item_sprite.visible = false

func _build_shotgun_cursor() -> Texture2D:
	if shotgun_cursor_texture == null:
		return null
	var tex_img := shotgun_cursor_texture.get_image()
	if tex_img == null:
		return shotgun_cursor_texture
	var copy_img := tex_img.duplicate()
	if copy_img.is_compressed():
		copy_img.decompress()
	var w := maxi(8, shotgun_cursor_size.x)
	var h := maxi(8, shotgun_cursor_size.y)
	if copy_img.get_width() != w or copy_img.get_height() != h:
		copy_img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(copy_img)

func _apply_cursor_for_slot(slot_index: int, force: bool = false) -> void:
	var use_shotgun_cursor := (slot_index == 2 and shotgun_cursor_texture != null)
	var sig := ""
	if use_shotgun_cursor:
		sig = "shotgun|" + str(shotgun_cursor_texture.resource_path) + "|" + str(shotgun_cursor_size) + "|" + str(shotgun_cursor_hotspot)
	else:
		sig = "default|" + str(_default_cursor_hotspot)

	if not force and sig == _last_cursor_sig:
		return
	_last_cursor_sig = sig

	if use_shotgun_cursor:
		_shotgun_scaled_cursor = _build_shotgun_cursor()
		var cur_tex := _shotgun_scaled_cursor if _shotgun_scaled_cursor != null else shotgun_cursor_texture
		var max_w := float(cur_tex.get_width()) - 1.0
		var max_h := float(cur_tex.get_height()) - 1.0
		var clamped_hotspot := Vector2(
			clampf(shotgun_cursor_hotspot.x, 0.0, maxf(0.0, max_w)),
			clampf(shotgun_cursor_hotspot.y, 0.0, maxf(0.0, max_h))
		)
		Input.set_custom_mouse_cursor(cur_tex, Input.CURSOR_ARROW, clamped_hotspot)
	elif _default_cursor_texture != null:
		Input.set_custom_mouse_cursor(_default_cursor_texture, Input.CURSOR_ARROW, _default_cursor_hotspot)

func _physics_process(delta: float) -> void:
	# Обновляем курсор при подгонке параметров в Инспекторе во время игры
	_apply_cursor_for_slot(current_weapon_slot, false)

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

	# 3.1. Кулдаун водяного пистолета, стрельба при зажатии ЛКМ и трата 1 литра раз в 5 секунд зажатия
	if water_cooldown_timer > 0:
		water_cooldown_timer -= delta

	var is_shooting_water := (
		current_weapon_slot == 1
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		and water_liters > 0.0
	)

	if is_shooting_water:
		if water_cooldown_timer <= 0:
			shoot_water_pistol()

		water_hold_drain_timer += delta
		if water_hold_drain_timer >= water_hold_drain_interval:
			water_hold_drain_timer -= water_hold_drain_interval
			water_liters = max(0.0, water_liters - 1.0)
			update_water_hud()
	else:
		water_hold_drain_timer = 0.0

	# 3.2. Кулдаун и таймер зарядки 1 патрона дробовика
	if shotgun_cooldown_timer > 0:
		shotgun_cooldown_timer -= delta

	if is_reloading_shotgun:
		shotgun_reload_timer -= delta
		if shotgun_reload_timer <= 0.0:
			shotgun_reload_timer = 0.0
			is_reloading_shotgun = false
			_reload_anim_offset = Vector2.ZERO
			_reload_anim_rot_deg = 0.0
			if current_weapon_slot == 2 and weapon_textures.size() > 2 and weapon_textures[2] != null and held_item_sprite != null:
				held_item_sprite.texture = weapon_textures[2]
			_on_shotgun_single_shell_reloaded()

	# 3.3. Таймер плавного исчезновения полноэкранной флешки (0.6 сек)
	if _flash_timer > 0.0:
		_flash_timer = max(0.0, _flash_timer - delta)
		if album_flash_ui != null:
			var ratio: float = _flash_timer / max(album_flash_duration, 0.001)
			var c := _flash_start_modulate
			c.a = _flash_start_modulate.a * ratio
			album_flash_ui.modulate = c
			if _flash_timer <= 0.0:
				album_flash_ui.visible = false
				is_album_active = false

	# 3.3.2. Ограничение длины звука после старта, если задано album_meme_sound_duration > 0
	if _meme_sound_timer > 0.0:
		_meme_sound_timer = max(0.0, _meme_sound_timer - delta)
		if album_meme_player != null and album_meme_player.playing:
			var fade_window: float = min(0.04, _meme_sound_total_duration * 0.25)
			if fade_window > 0.0 and _meme_sound_timer <= fade_window:
				var fade_ratio: float = _meme_sound_timer / fade_window
				album_meme_player.volume_db = lerp(-36.0, album_meme_sound_volume_db, fade_ratio)
		if _meme_sound_timer <= 0.0:
			if album_meme_player != null and album_meme_player.playing:
				album_meme_player.stop()
			if album_meme_player != null:
				album_meme_player.volume_db = album_meme_sound_volume_db

	# 3.4. Обратный отсчёт альбома с 12 секунд (12, 11, 10 ... 2, 1 -> Ready for larp)
	if album_cooldown_left > 0.0:
		album_cooldown_left = max(0.0, album_cooldown_left - delta)
		var shown_num := int(ceil(album_cooldown_left))
		if shown_num != _last_shown_countdown:
			_last_shown_countdown = shown_num
			update_album_hud()
		if album_cooldown_left <= 0.0:
			_last_shown_countdown = -1
			update_album_hud()

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

# Обработка одиночного клика ЛКМ для молотка/дробовика/альбома и клавиши R для перезарядки
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reload_shotgun()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_weapon_slot == 0 and not is_hitting_self and hit_cooldown_timer <= 0:
			start_self_hit()
		elif current_weapon_slot == 2 and shotgun_cooldown_timer <= 0:
			shoot_shotgun()
		elif current_weapon_slot == 3 and not is_album_active and album_cooldown_left <= 0.0:
			use_photo_album()

func use_photo_album() -> void:
	if album_range_scene == null:
		push_warning("Не назначен album_range_scene в инспекторе игрока!")
		return
	
	is_album_active = true
	album_cooldown_left = album_cooldown_duration
	_last_shown_countdown = int(ceil(album_cooldown_left))
	update_album_hud()

	var range_instance = album_range_scene.instantiate()
	range_instance.duration = album_range_duration
	
	var parent_node = get_parent() if get_parent() != null else get_tree().current_scene
	parent_node.add_child(range_instance)
	
	if range_instance.has_signal("finished_range"):
		range_instance.finished_range.connect(_on_album_range_finished)
	
	if range_instance.has_method("setup"):
		range_instance.setup(global_position, get_global_mouse_position(), self)

func _on_album_range_finished(triggered_any_npc: bool) -> void:
	_on_album_effect_applied(triggered_any_npc)
	_show_random_album_meme()

# Заготовка на будущее: реакция игрока/игры после завершения показа зоны альбома
func _on_album_effect_applied(triggered_any_npc: bool) -> void:
	print("Зона альбома отработала. Задет NPC: ", triggered_any_npc)

func _play_album_meme_sound() -> void:
	if album_meme_player != null and album_meme_sound != null:
		album_meme_player.stream = album_meme_sound
		album_meme_player.volume_db = album_meme_sound_volume_db
		var start_pos: float = max(0.0, album_meme_sound_start_at)
		var stream_len: float = album_meme_sound.get_length()
		if stream_len > 0.0 and start_pos >= stream_len:
			start_pos = 0.0
		album_meme_player.play(start_pos)
		if album_meme_sound_duration > 0.0:
			_meme_sound_total_duration = album_meme_sound_duration
			_meme_sound_timer = album_meme_sound_duration
		else:
			_meme_sound_total_duration = 0.0
			_meme_sound_timer = 0.0

func _show_random_album_meme() -> void:
	var valid_memes: Array[Texture2D] = []
	for tex in album_memes:
		if tex != null:
			valid_memes.append(tex)
	
	if valid_memes.size() <= 0:
		is_album_active = false
		return

	var chosen_tex: Texture2D = valid_memes[randi() % valid_memes.size()]
	_play_album_meme_sound()

	if album_flash_ui != null:
		album_flash_ui.texture = chosen_tex
		album_flash_ui.visible = true
		album_flash_ui.modulate = _flash_start_modulate
		_flash_timer = max(album_flash_duration, 0.05)
	else:
		is_album_active = false

func collect_shotgun_ammo(amount: int = 1) -> bool:
	# У себя можно хранить до max_reserve_shotgun_ammo (2 патрона) независимо от патронов в самом дробовике
	if reserve_shotgun_ammo >= max_reserve_shotgun_ammo:
		print("Лимит патронов у себя уже достигнут (", max_reserve_shotgun_ammo, ")")
		return false
	
	var can_add: int = mini(amount, max_reserve_shotgun_ammo - reserve_shotgun_ammo)
	reserve_shotgun_ammo += can_add
	update_shotgun_hud()
	print("Подобрано патронов: +", can_add, " | У себя в запасе: ", reserve_shotgun_ammo, "/", max_reserve_shotgun_ammo, " | В дробовике: ", shotgun_ammo_in_mag, "/", max_shotgun_ammo)
	return true

func reload_shotgun() -> void:
	if is_reloading_shotgun:
		return
	if shotgun_ammo_in_mag >= max_shotgun_ammo:
		print("Дробовик уже полон: ", shotgun_ammo_in_mag, "/", max_shotgun_ammo)
		return
	if reserve_shotgun_ammo <= 0:
		print("Нет патронов у себя для зарядки!")
		return
	
	# Заряжаем строго 1 патрон за нажатие R + запускаем быструю анимацию картинки
	reserve_shotgun_ammo -= 1
	shotgun_ammo_in_mag += 1
	update_shotgun_hud()
	is_reloading_shotgun = true
	shotgun_reload_timer = max(shotgun_reload_duration, 0.05)
	_play_single_shell_reload_anim(shotgun_reload_timer)
	print("Заряжен 1 патрон! В дробовике: ", shotgun_ammo_in_mag, "/", max_shotgun_ammo, " | У себя в запасе: ", reserve_shotgun_ammo, "/", max_reserve_shotgun_ammo)

func _play_single_shell_reload_anim(duration: float) -> void:
	if _current_reload_tween != null and _current_reload_tween.is_valid():
		_current_reload_tween.kill()

	_reload_anim_offset = Vector2.ZERO
	_reload_anim_rot_deg = 0.0

	if held_item_sprite != null and shotgun_reload_texture != null:
		held_item_sprite.texture = shotgun_reload_texture
		held_item_sprite.visible = true
		held_item_sprite.self_modulate = Color(1, 1, 1, 1)

	var half_t: float = duration * 0.5
	_current_reload_tween = create_tween()
	_current_reload_tween.set_parallel(true)
	_current_reload_tween.tween_property(self, "_reload_anim_offset", shotgun_reload_kick, half_t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_current_reload_tween.tween_property(self, "_reload_anim_rot_deg", -14.0, half_t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_current_reload_tween.chain().set_parallel(true)
	_current_reload_tween.tween_property(self, "_reload_anim_offset", Vector2.ZERO, half_t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_current_reload_tween.tween_property(self, "_reload_anim_rot_deg", 0.0, half_t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_shotgun_single_shell_reloaded() -> void:
	# Заготовка под дополнительные эффекты при завершении зарядки 1 патрона
	pass

func shoot_shotgun() -> void:
	if is_reloading_shotgun:
		return
	if shotgun_ammo_in_mag <= 0:
		print("Дробовик разряжен! Подбери патроны и нажми R.")
		return
	if shotgun_blast_scene == null:
		push_warning("Не назначен shotgun_blast_scene в инспекторе игрока!")
		return
	
	shotgun_ammo_in_mag -= 1
	shotgun_cooldown_timer = shotgun_fire_cooldown
	update_shotgun_hud()
	_play_shotgun_effects()
	print("Выстрел из дробовика! Осталось в стволе: ", shotgun_ammo_in_mag, "/", max_shotgun_ammo)
	
	var start_pos: Vector2 = global_position + shotgun_muzzle_offset
	if held_item_sprite != null and held_item_sprite.visible:
		var local_tip = shotgun_muzzle_offset
		if held_item_sprite.flip_v:
			local_tip.y = -local_tip.y
		start_pos = held_item_sprite.to_global(local_tip)
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var blast_instance = shotgun_blast_scene.instantiate()
	
	var parent_node = get_parent() if get_parent() != null else get_tree().current_scene
	parent_node.add_child(blast_instance)
	
	if blast_instance.has_method("setup"):
		blast_instance.setup(start_pos, mouse_pos, self, shotgun_muzzle_offset)

func _play_shotgun_effects() -> void:
	# 1. Приглушённый краткий звук выстрела
	if shotgun_shot_player != null and shotgun_shot_sound != null:
		shotgun_shot_player.stream = shotgun_shot_sound
		shotgun_shot_player.volume_db = shotgun_shot_volume_db
		shotgun_shot_player.play()

	# 2. Тряска камеры после выстрела (без блокировки мотки камеры)
	_trigger_tiny_camera_shake()

	# 3. Звон в ушах на 5-6 сек с наложением при повторных выстрелах
	_spawn_overlapping_ringing()

func _trigger_tiny_camera_shake() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	if _active_camera != cam:
		_active_camera = cam
		_last_shake_jitter = Vector2.ZERO
	_shake_timer = camera_shake_duration

func _spawn_overlapping_ringing() -> void:
	if ringing_sound == null:
		return
	var player := AudioStreamPlayer.new()
	if ringing_player != null:
		player.bus = ringing_player.bus
	player.stream = ringing_sound
	player.volume_db = ringing_start_db
	add_child(player)
	player.play()
	_active_ringings.append({
		"player": player,
		"time_left": ringing_duration
	})

# Заготовка на будущее: реакция игрока/игры при попадании дробовика по NPC
func _on_shotgun_hit_npc(npc_node: Node, _hit_pos: Vector2) -> void:
	print("Игрок попал из дробовика по NPC: ", npc_node.name)

func shoot_water_pistol() -> void:
	if water_stream_scene == null:
		push_warning("Не назначен water_stream_scene в инспекторе игрока!")
		return

	if water_liters <= 0.0:
		return
	
	water_cooldown_timer = water_fire_cooldown
	
	var start_pos: Vector2 = global_position + water_muzzle_offset
	if held_item_sprite != null and held_item_sprite.visible:
		var local_tip = water_muzzle_offset
		if held_item_sprite.flip_v:
			local_tip.y = -local_tip.y
		start_pos = held_item_sprite.to_global(local_tip)
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var stream_instance = water_stream_scene.instantiate()
	
	# Спавним струю в родительском узле (например, в World), а внутри самой струи обновляем её координаты вместе с игроком
	var parent_node = get_parent() if get_parent() != null else get_tree().current_scene
	parent_node.add_child(stream_instance)
	
	if stream_instance.has_method("setup"):
		stream_instance.setup(start_pos, mouse_pos, self, water_muzzle_offset)

# Заготовка на будущее: реакция игрока/игры при попадании воды по NPC
func _on_water_hit_npc(npc_node: Node, _hit_pos: Vector2) -> void:
	# Сюда можно будет добавить эффекты для игрока (например, изменение кортизола/красоты или счётчик)
	print("Игрок попал из водяного пистолета по NPC: ", npc_node.name)

func start_self_hit() -> void:
	is_hitting_self = true
	hit_cooldown_timer = 1.5  # Твое значение кулдауна
	print("Игрок бьет себя молотком по лицу!")
	
	# Звук удара комфортной громкости (0.4)
	if audio_stream_player != null:
		if hit_sound != null:
			audio_stream_player.stream = hit_sound
		audio_stream_player.volume_db = linear_to_db(0.14)
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
func _process(delta: float) -> void:
	# Тряска камеры поверх текущего offset (не мешает мотке камеры в разные стороны)
	if _active_camera != null and is_instance_valid(_active_camera):
		_active_camera.offset -= _last_shake_jitter
		_last_shake_jitter = Vector2.ZERO

		if _shake_timer > 0.0:
			_shake_timer = max(0.0, _shake_timer - delta)
			var progress: float = 1.0 - (_shake_timer / max(camera_shake_duration, 0.0001))
			var decay: float = pow(1.0 - progress, 2.0)
			var current_mag: float = camera_shake_strength * decay
			_last_shake_jitter = Vector2(
				randf_range(-current_mag, current_mag),
				randf_range(-current_mag, current_mag)
			)
			_active_camera.offset += _last_shake_jitter

	# Постепенное уменьшение каждого активного звона в ушах
	for i in range(_active_ringings.size() - 1, -1, -1):
		var entry: Dictionary = _active_ringings[i]
		var time_left: float = max(0.0, float(entry["time_left"]) - delta)
		entry["time_left"] = time_left
		var player: AudioStreamPlayer = entry["player"]
		if player == null or not is_instance_valid(player):
			_active_ringings.remove_at(i)
			continue
		var elapsed_ratio: float = 1.0 - (time_left / max(ringing_duration, 0.001))
		if player.playing:
			player.volume_db = lerp(ringing_start_db, ringing_min_db, elapsed_ratio)
		if time_left <= 0.0:
			player.stop()
			player.queue_free()
			_active_ringings.remove_at(i)

	if held_item_sprite != null and held_item_sprite.visible and current_weapon_slot != -1:
		# --- ОТДЕЛЬНАЯ АНИМАЦИЯ ПЕРЕЗАРЯДКИ ОДНОГО ПАТРОНА ДРОБОВИКА ---
		if is_reloading_shotgun and shotgun_reload_texture != null:
			held_item_sprite.texture = shotgun_reload_texture
			held_item_sprite.scale = shotgun_reload_scale
			held_item_sprite.position = shotgun_reload_offset + _reload_anim_offset
			held_item_sprite.rotation = deg_to_rad(shotgun_reload_rotation + _reload_anim_rot_deg)
			held_item_sprite.flip_v = false
			held_item_sprite.flip_h = shotgun_reload_flip_h
			return

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

# --- ОБНОВЛЕНИЕ HUD ПО ТЕКУЩЕМУ СЛОТУ ---
func update_weapon_hud_visibility() -> void:
	if water_hud != null:
		water_hud.visible = (current_weapon_slot == 1)
	if shotgun_hud != null:
		shotgun_hud.visible = (current_weapon_slot == 2)
	if album_hud != null:
		album_hud.visible = (current_weapon_slot == 3)

func update_water_hud() -> void:
	if water_amount_label != null:
		var max_val := int(round(max_water_liters))
		var cur_val := clampi(int(floor(water_liters)), 0, max_val)
		water_amount_label.text = str(cur_val) + "/" + str(max_val) + "L"

func update_shotgun_hud() -> void:
	if shotgun_ammo_label != null:
		shotgun_ammo_label.text = str(shotgun_ammo_in_mag) + "/" + str(max_shotgun_ammo)
	if shotgun_reserve_label != null:
		shotgun_reserve_label.text = str(reserve_shotgun_ammo) + "/" + str(max_reserve_shotgun_ammo)

func update_album_hud() -> void:
	if album_status_label != null:
		if album_cooldown_left > 0.0:
			album_status_label.text = str(int(ceil(album_cooldown_left)))
		else:
			album_status_label.text = "Ready for larp"

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
	
	if beauty_ui != null and beauty_stages.size() > stage_index:
		if beauty_stages[stage_index] != null:
			beauty_ui.texture = beauty_stages[stage_index]
	
	var rank_names = ["Sub3", "LTN", "Chad", "True Adam"]
	print("Красота: ", beauty, " | Ранг: ", rank_names[stage_index])

# --- ФУНКЦИИ УПРАВЛЕНИЯ ОРУЖИЕМ В РУКАХ ---
func equip_weapon(slot_index: int) -> void:
	# Если меняем оружие во время удара — прерываем анимацию молотка
	if is_hitting_self:
		is_hitting_self = false
		if current_hit_tween and current_hit_tween.is_valid():
			current_hit_tween.kill()

	# Если сменили слот во время перезарядки — сбрасываем анимацию перезарядки
	if is_reloading_shotgun:
		is_reloading_shotgun = false
		shotgun_reload_timer = 0.0
		_reload_anim_offset = Vector2.ZERO
		_reload_anim_rot_deg = 0.0
		if _current_reload_tween != null and _current_reload_tween.is_valid():
			_current_reload_tween.kill()

	current_weapon_slot = slot_index
	_apply_cursor_for_slot(current_weapon_slot, false)
	update_weapon_hud_visibility()
	
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
