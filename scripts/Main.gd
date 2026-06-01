extends Node2D

const COLLECTIBLE_SCENE := preload("res://scenes/Collectible.tscn")
const POPUP_NONE := 0
const POPUP_MEMORY := 1
const POPUP_FINAL := 2

# TODO: Change popup texts here when revising the narrative adaptation.
const MEMORIES := [
	{
		"name": "Figurinha-flor",
		"message": "A figurinha mais bonita da coleção desapareceu. Zaíta ainda procura a menina que carregava flores.",
		"icon_index": 0,
	},
	{
		"name": "Boneca negra",
		"message": "A bonequinha tinha um braço só e parecia sorrir. Mesmo incompleta, continuava sendo a mais bonita.",
		"icon_index": 1,
	},
	{
		"name": "Lápis de cera vermelho",
		"message": "Um pequeno pedaço de lápis vermelho fazia parte de uma troca que nunca aconteceu.",
		"icon_index": 2,
	},
	{
		"name": "Lápis de cera amarelo",
		"message": "O lápis amarelo lembra os desenhos guardados com cuidado e as escolhas difíceis entre irmãs.",
		"icon_index": 2,
	},
	{
		"name": "Chapinha de garrafa",
		"message": "Nas mãos das meninas, uma chapinha podia virar brinquedo. Havia imaginação mesmo onde quase nada sobrava.",
		"icon_index": 3,
	},
	{
		"name": "Latinha vazia",
		"message": "A latinha fazia barulho dentro da caixa de papelão. Era simples, mas também guardava uma história de infância.",
		"icon_index": 4,
	},
	{
		"name": "Caixa de fósforos",
		"message": "Entre brinquedos espalhados pelo chão, a caixa pequena lembra a casa apertada e o cansaço da mãe.",
		"icon_index": 5,
	},
	{
		"name": "Palitos usados",
		"message": "Zaíta procurava insistentemente a flor perdida. Cada objeto encontrado tornava a ausência ainda maior.",
		"icon_index": 6,
	},
]

@onready var maze_generator: MazeGenerator = $MazeGenerator
@onready var collectibles_container: Node2D = $Collectibles
@onready var player: ZaitaPlayer = $Player
@onready var counter_label: Label = %CounterLabel
@onready var start_popup: StartPopup = $UI/StartPopup
@onready var message_popup: PopupMessage = $UI/PopupMessage

var _collected_count := 0
var _total_collectibles := 0
var _popup_context := POPUP_NONE


func _ready() -> void:
	start_popup.start_requested.connect(_on_start_requested)
	message_popup.closed.connect(_on_message_popup_closed)
	player.set_movement_enabled(false)
	message_popup.hide_message()
	_update_counter()
	start_popup.open()


func _reset_game() -> void:
	player.set_movement_enabled(false)
	message_popup.hide_message()
	_popup_context = POPUP_NONE
	_collected_count = 0

	for child in collectibles_container.get_children():
		child.queue_free()

	var maze_data := maze_generator.generate()
	var spawn_cell: Vector2i = maze_data["spawn_cell"]
	player.global_position = maze_generator.cell_to_global_position(spawn_cell)
	player.configure_camera_bounds(maze_generator.get_global_pixel_rect())

	var collectible_cells := maze_generator.pick_collectible_cells(
		maze_generator.collectible_count,
		spawn_cell
	)
	_total_collectibles = collectible_cells.size()
	for index in range(_total_collectibles):
		_spawn_collectible(collectible_cells[index], index)

	_update_counter()


func _spawn_collectible(cell: Vector2i, index: int) -> void:
	var collectible := COLLECTIBLE_SCENE.instantiate() as NarrativeCollectible
	var memory: Dictionary = MEMORIES[index % MEMORIES.size()]
	collectibles_container.add_child(collectible)
	collectible.global_position = maze_generator.cell_to_global_position(cell)
	collectible.configure(memory["name"], memory["message"], memory["icon_index"])
	collectible.collected.connect(_on_collectible_collected)


func _on_start_requested() -> void:
	_reset_game()
	player.set_movement_enabled(true)


func _on_collectible_collected(collectible: NarrativeCollectible) -> void:
	_collected_count += 1
	_update_counter()
	player.set_movement_enabled(false)
	_popup_context = POPUP_MEMORY
	message_popup.show_message(collectible.object_name, collectible.narrative_message)
	collectible.queue_free()


func _on_message_popup_closed() -> void:
	if _popup_context == POPUP_MEMORY and _collected_count >= _total_collectibles:
		_popup_context = POPUP_FINAL
		message_popup.show_message(
			"Memórias reunidas",
			"Os brinquedos contam uma infância feita de imaginação, cuidado e ausências. A busca termina, mas a história permanece.",
			"Jogar novamente"
		)
		return

	if _popup_context == POPUP_FINAL:
		_reset_game()
		player.set_movement_enabled(true)
		return

	_popup_context = POPUP_NONE
	player.set_movement_enabled(true)


func _update_counter() -> void:
	counter_label.text = "Coletados: %d / %d" % [_collected_count, _total_collectibles]


# TODO: Add sound effects for footsteps, collection and popup transitions.
# TODO: Add more phases only after the first exploration loop is validated.
