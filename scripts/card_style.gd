extends RefCounted
## Presentation only. Ownership and rarity come from the shared runtime card.
const OWNERS := {
	"common": ["무색 · 공용", "8d9299"],
	"mira": ["미라 전용", "668b6e"],
	"kalian": ["칼리안 전용", "a65760"],
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
	var owner: String = card.get("character", "common")
	var entry: Array = OWNERS.get(owner, [owner + " 전용", "8d9299"])
	var rarity: String = card.get("rarity", "일반")
	return {"owner_label": entry[0], "owner_color": Color(entry[1]), "rarity_color": Color(RARITIES.get(rarity, "8c929b"))}
