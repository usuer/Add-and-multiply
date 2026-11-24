class_name CharacterState
extends Resource

@export var character_id: String = ""
@export var display_name: String = ""
@export var affection: int = 0
@export var respect: int = 0
@export var trust: int = 0
@export var resentment: int = 0
@export var courage: int = 50
@export var conscience: int = 50
@export var ambition: int = 50
@export var violence_acceptance: int = 20
@export var grievance: int = 0
@export var memories: Array[Dictionary] = []

func remember(cycle: int, kind: String, summary: String, changes: Dictionary = {}) -> void:
	for key: String in changes:
		var amount := int(changes[key])
		match key:
			"affection": affection = clampi(affection + amount, -100, 100)
			"respect": respect = clampi(respect + amount, -100, 100)
			"trust": trust = clampi(trust + amount, -100, 100)
			"resentment": resentment = clampi(resentment + amount, 0, 100)
			"grievance": grievance = clampi(grievance + amount, 0, 100)
	memories.append({"cycle": cycle, "kind": kind, "summary": summary})

func to_data() -> Dictionary:
	return {
		"character_id": character_id, "display_name": display_name,
		"affection": affection, "respect": respect, "trust": trust,
		"resentment": resentment, "courage": courage, "conscience": conscience,
		"ambition": ambition, "violence_acceptance": violence_acceptance,
		"grievance": grievance, "memories": memories.duplicate(true)
	}

static func from_data(data: Dictionary) -> CharacterState:
	var character := CharacterState.new()
	character.character_id = str(data.get("character_id", ""))
	character.display_name = str(data.get("display_name", ""))
	character.affection = clampi(int(data.get("affection", 0)), -100, 100)
	character.respect = clampi(int(data.get("respect", 0)), -100, 100)
	character.trust = clampi(int(data.get("trust", 0)), -100, 100)
	character.resentment = clampi(int(data.get("resentment", 0)), 0, 100)
	character.courage = clampi(int(data.get("courage", 50)), 0, 100)
	character.conscience = clampi(int(data.get("conscience", 50)), 0, 100)
	character.ambition = clampi(int(data.get("ambition", 50)), 0, 100)
	character.violence_acceptance = clampi(int(data.get("violence_acceptance", 20)), 0, 100)
	character.grievance = clampi(int(data.get("grievance", 0)), 0, 100)
	character.memories.assign(data.get("memories", []))
	return character
