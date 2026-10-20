extends RefCounted
## Short explanations of the game words on a card (중독, 소모, 부작용 ...), shown beside a hovered card so nobody has to guess.
const Data = preload("res://scripts/game_data.gd")
const BattleTooltip = preload("res://scripts/battle_tooltip.gd")
const MAX_ENTRIES := 4
## word on the card -> status id (its tooltip text comes from the status record, so the two never disagree)
const STATUS_WORDS := {"중독": "poison", "맹독": "venom", "취약": "vulnerable", "약화": "weak", "반격": "counter", "방어막": "barrier", "힘": "strength", "죄목": "sin", "쥐": "rats", "불씨": "embers"}
## word on the card -> explanation (words that are not statuses)
const WORDS := {
	"방어도": "받는 피해를 먼저 막아 줍니다. 내 턴이 시작되면 사라집니다.",
	"소모": "사용하면 이번 전투에서 제외됩니다. 전투가 끝나면 덱으로 돌아옵니다.",
	"휘발": "턴이 끝날 때 손에 있으면 소모됩니다.",
	"유지": "턴이 끝나도 손에 남습니다.",
	"부작용": "사용할 수 없는 카드입니다. 버린 카드 더미에 섞여 들어오고, 손에 들어온 채 턴이 끝나면 소모됩니다.",
	"조제": "무작위 포션 1개를 포션 벨트에 만듭니다. 벨트가 가득 차 있으면 만들어지지 않습니다.",
	"포션": "전투 중 벨트에서 눌러 쓸 수 있는 소모품입니다. 벨트에는 3개까지 가집니다.",
	"에너지": "카드를 사용하는 데 쓰는 자원입니다. 매 턴 3으로 시작합니다.",
}
## The order the words are looked up in (the first ones found are shown, up to MAX_ENTRIES).
const ORDER := ["죄목", "쥐", "불씨", "중독", "맹독", "취약", "약화", "소모", "휘발", "유지", "부작용", "조제", "반격", "방어막", "방어도", "포션"]

## [{title, body}] for the words that appear in the card's text, in ORDER.
static func entries_for(card: Dictionary) -> Array:
	var text := Data.effect_text(card) + " " + " ".join(card.get("keywords", []))
	var found: Array = []
	for word in ORDER:
		if found.size() >= MAX_ENTRIES: break
		if not text.contains(word): continue
		if STATUS_WORDS.has(word):
			var record := Data.find_record("powers", str(STATUS_WORDS[word]))
			if record.is_empty(): continue
			found.append({"title": str(record.get("name", word)), "body": str(record.get("tooltip", record.get("effect", "")))})
		elif WORDS.has(word):
			found.append({"title": word, "body": str(WORDS[word])})
	return found

## A column of small panels, one per word; empty column when the card has none.
static func build(card: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.name = "KeywordHelp"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	for entry in entries_for(card):
		var panel := BattleTooltip.build_titled(str(entry.title), str(entry.body))
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(panel)
	return column
