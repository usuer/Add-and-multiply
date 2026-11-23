class_name FactionState
extends Resource

@export var faction_id: String = ""
@export var display_name: String = ""
@export var disposition: int = 0
@export var known_reasons: Array[Dictionary] = []

func react(cycle: int, amount: int, reason: String) -> void:
	disposition = clampi(disposition + amount, -100, 100)
	known_reasons.append({"cycle": cycle, "amount": amount, "reason": reason})

func latest_reaction() -> String:
	if known_reasons.is_empty():
		return "Пока нет заметной реакции."
	return str(known_reasons.back().get("reason", ""))

func to_data() -> Dictionary:
	return {
		"faction_id": faction_id, "display_name": display_name,
		"disposition": disposition, "known_reasons": known_reasons.duplicate(true)
	}

static func from_data(data: Dictionary) -> FactionState:
	var faction := FactionState.new()
	faction.faction_id = str(data.get("faction_id", ""))
	faction.display_name = str(data.get("display_name", ""))
	faction.disposition = clampi(int(data.get("disposition", 0)), -100, 100)
	faction.known_reasons.assign(data.get("known_reasons", []))
	return faction
