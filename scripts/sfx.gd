extends Node
## Short sound effects on an "SFX" bus. A sound is a file `assets/audio/sfx/<name>.wav` (or .ogg; the current set is Kenney's CC0 packs, see CREDITS.txt); a name without a file is simply silent,
## so the game plays the same before and after the sounds are delivered. Volume and mute follow the music settings (music.gd).
const DIR := "res://assets/audio/sfx/"
const BUS := "SFX"
const VOICES := 8
## Every name the game asks for, with what it is for (this list is also the request to whoever makes the sounds).
const NAMES := {
	"ui_click": "button pressed (0.08 s soft wooden tick)",
	"ui_hover": "pointer over a button (0.05 s very quiet tick)",
	"card_attack": "an attack card is played (0.4 s blade swish)",
	"card_skill": "a skill card is played (0.5 s soft chime shimmer)",
	"card_power": "a power card is played (1.0 s low swelling hum)",
	"hit_enemy": "damage lands on the enemy (0.3 s dull impact)",
	"hit_player": "the hero loses HP (0.3 s heavier thud with a short grunt-free groan)",
	"block_gain": "block gained (0.3 s metallic clink)",
	"heal": "HP restored (0.8 s warm rising chime)",
	"poison": "poison applied (0.6 s wet bubbling)",
	"potion": "a potion is drunk (0.7 s glass clink and gulp)",
	"turn_end": "end of the hero's turn (0.3 s low tick)",
	"map_step": "stepping to the next room (0.4 s soft footstep on stone)",
	"event_open": "a story page opens (0.5 s paper turning)",
	"shop_buy": "a purchase (0.6 s coins and cloth)",
	"relic_get": "a relic is taken (1.2 s bell with a faint shimmer)",
	"victory": "a fight is won (2.5 s short restrained sting, no loop)",
	"defeat": "the run is lost (3.0 s low toll fading out, no loop)",
	"ending_toll": "the closing scene begins (4.0 s single deep bell with long tail)",
	"card_draw": "cards are drawn (0.25 s paper-and-card slide)",
	"shuffle": "the discard pile is shuffled back (0.7 s quick card riffle)",
	"enemy_death": "the enemy falls (0.9 s heavy cloth and wood collapse with a low breath)",
	"debuff_apply": "a harmful status lands on the hero (0.5 s dull descending tone)",
	"gold_gain": "gold received (0.4 s two soft coins)",
	"card_pick": "a reward card is taken (0.35 s card set down on wood)",
	"card_upgrade": "a card is upgraded (0.8 s hammer ping on metal with a short ring)",
	"card_remove": "a card is removed from the deck (0.7 s paper tearing and a brief ember crackle)",
	"boss_intro": "a boss fight begins (2.0 s low brass-free drone with one slow bell strike)",
}
## Per-sound trim in dB for the Kenney (CC0) set: interface ticks are loud next to the others.
const GAIN_DB := {"ui_click": -5.0, "ui_hover": -10.0, "map_step": -3.0, "card_draw": -4.0, "shuffle": -4.0}
var voices: Array[AudioStreamPlayer] = []
var cache := {}
var next_voice := 0
var last_hover := 0

func _ready() -> void:
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		voices.append(player)

func stream_for(id: String) -> AudioStream:
	if cache.has(id): return cache[id]
	var found: AudioStream = null
	for extension in ["wav", "ogg"]:
		var file := "%s%s.%s" % [DIR, id, extension]
		if ResourceLoader.exists(file):
			found = load(file) as AudioStream
			break
	cache[id] = found
	return found

## Plays the sound once. `pitch` lets the same sample be a little different each time.
func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not is_inside_tree(): return
	var stream := stream_for(id)
	if stream == null: return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = stream
	voice.pitch_scale = pitch
	voice.volume_db = volume_db + float(GAIN_DB.get(id, 0.0))
	voice.play()

## Button clicks and hovers for every button in the game, without touching each screen: buttons announce themselves as they enter the tree.
func watch_buttons(tree: SceneTree) -> void:
	tree.node_added.connect(func(node: Node):
		if node is BaseButton:
			node.pressed.connect(func(): play("ui_click", randf_range(0.96, 1.04)))
			node.mouse_entered.connect(func():
				# one hover tick per button at most every 60 ms, so sweeping across a row of buttons stays soft
				var now := Time.get_ticks_msec()
				if now - last_hover > 60:
					last_hover = now
					play("ui_hover")))
