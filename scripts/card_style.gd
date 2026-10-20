extends RefCounted
## Presentation only. Ownership and rarity come from the shared runtime card.
const OWNERS := {
	"common": ["무색 · 공용", "8d9299"],
	"mira": ["미라 전용", "8062ad"],
	"kalian": ["칼리안 전용", "a65760"],
	"severin": ["세버린 전용", "b0453f"],
	"calamo": ["칼라모 전용", "8f9c58"],
	"esca": ["에스카 전용", "d98a3e"],
	"sera": ["세라 전용", "8870b1"],
	"lucian": ["루시안 전용", "b7a779"],
	"leonhardt": ["레온하르트 전용", "76889b"],
	"erisha": ["에리샤 전용", "64948d"],
	"morgan": ["모르간 전용", "965f95"],
	"kain": ["카인 전용", "a58065"],
	"bella": ["벨라 전용", "9f426a"],
	"isaac": ["아이작 전용", "a58c52"],
	"sylvia": ["실비아 전용", "76a0b4"],
	"drake": ["드레이크 전용", "b16543"]
}
const RARITIES := {"일반": "8c929b", "고급": "61977e", "희귀": "648fbd", "영웅": "a076be", "전설": "c69b51"}

static func resolve(card: Dictionary) -> Dictionary:
	var owner: String = card.get("visual_character", card.get("character", "common"))
	var entry: Array = OWNERS.get(owner, [owner + " 전용", "8d9299"])
	var label: String = entry[0]
	if card.has("visual_character") and card.get("character", "common") == "common":
		label = label.replace("전용", "기본")
	var rarity: String = card.get("rarity", "일반")
	return {"owner_label": label, "owner_color": Color(entry[1]), "rarity_color": Color(RARITIES.get(rarity, "8c929b"))}
