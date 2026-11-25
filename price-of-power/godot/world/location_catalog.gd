class_name LocationCatalog
extends RefCounted

const DEFINITIONS: Dictionary = {
	"castle": {
		"title": "Тронный зал Ардена",
		"texture": "res://assets/art/castle_hall.png",
		"hotspots": {
			"spouse": Vector2(0.23, 0.47), "sister": Vector2(0.40, 0.53),
			"secretary": Vector2(0.59, 0.46), "borin": Vector2(0.79, 0.46)
		}
	},
	"barracks": {
		"title": "Казармы и военный двор",
		"texture": "res://assets/art/barracks_yard.png",
		"hotspots": {"daren": Vector2(0.27, 0.55), "radomir": Vector2(0.68, 0.54)}
	},
	"market": {"title": "Рынок Ардена", "hotspots": {
		"zlata": Vector2(0.24, 0.57), "miron": Vector2(0.5, 0.55), "aglaia": Vector2(0.76, 0.58)
	}},
	"school": {"title": "Школьный двор", "hotspots": {"tikhon": Vector2(0.55, 0.57)}},
	"granary": {"title": "Княжеские амбары", "hotspots": {"granary_keeper": Vector2(0.46, 0.54)}},
	"embassy": {"title": "Двор послов", "hotspots": {"envoy": Vector2(0.40, 0.51), "vardan": Vector2(0.68, 0.54)}},
	"temple": {"title": "Храмовый двор", "hotspots": {"chaplain": Vector2(0.38, 0.54), "savva": Vector2(0.65, 0.57)}},
	"smithy": {"title": "Оружейная кузница", "hotspots": {"forge_master": Vector2(0.54, 0.58)}}
}

static func has_location(location_id: String) -> bool:
	return DEFINITIONS.has(location_id)

static func definition(location_id: String) -> Dictionary:
	return (DEFINITIONS.get(location_id, {}) as Dictionary).duplicate(true)
