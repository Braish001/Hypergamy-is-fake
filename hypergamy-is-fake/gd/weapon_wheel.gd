extends Control

# Перетащи своего Игрока сюда прямо из дерева сцены через Инспектор!
@export var player_node: CharacterBody2D

@onready var items: Array[TextureRect] = [
	$TextureRect,     # Слот 1 (Клавиша 1)
	$TextureRect2,    # Слот 2 (Клавиша 2)
	$TextureRect3,    # Слот 3 (Клавиша 3)
	$TextureRect4     # Слот 4 (Клавиша 4)
]

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var current_slot: int = -1

var normal_color: Color = Color(0.6, 0.6, 0.6, 0.65)
var selected_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var normal_scale: Vector2 = Vector2(1.0, 1.0)
var selected_scale: Vector2 = Vector2(1.25, 1.25)

func _ready() -> void:
	for item in items:
		if item != null:
			item.self_modulate = normal_color
			item.scale = normal_scale
			item.pivot_offset = item.size / 2
	reset_all_items()

# Используем _input, чтобы гарантированно ловить нажатия цифр
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				select_item(0)
			KEY_2:
				select_item(1)
			KEY_3:
				select_item(2)
			KEY_4:
				select_item(3)

func select_item(index: int) -> void:
	if current_slot == index:
		current_slot = -1
		print("Убрали предмет в карман")
		reset_all_items()
		notify_player(-1)
		return
		
	current_slot = index
	print("Выбран слот: ", current_slot + 1)
	
	if audio_player != null and audio_player.stream != null:
		audio_player.play()
	
	notify_player(current_slot)
	
	for i in range(items.size()):
		var item = items[i]
		if item == null:
			continue
			
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if i == current_slot:
			item.z_index = 10
			tween.tween_property(item, "self_modulate", selected_color, 0.15)
			tween.tween_property(item, "scale", selected_scale, 0.15)
		else:
			item.z_index = 0
			tween.tween_property(item, "self_modulate", normal_color, 0.15)
			tween.tween_property(item, "scale", normal_scale, 0.15)

func reset_all_items() -> void:
	for item in items:
		if item != null:
			item.z_index = 0
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(item, "self_modulate", normal_color, 0.15)
			tween.tween_property(item, "scale", normal_scale, 0.15)

func notify_player(slot: int) -> void:
	if player_node != null and player_node.has_method("equip_weapon"):
		player_node.equip_weapon(slot)
	else:
		print("ОШИБКА: К интерфейсу не привязан узел Player в Инспекторе!")
