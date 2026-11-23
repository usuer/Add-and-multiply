class_name PopulationState
extends Resource

@export var residents: int = 18400
@export var monthly_migration: int = 0
@export var unrest: int = 18
@export var rebellion_active: bool = false
@export var history: Array[Dictionary] = []

func advance_month(state: WorldState) -> void:
	var rural_attitude := (state.factions["rural"] as FactionState).disposition
	var pressure := 0
	if state.public_health < 45: pressure += 3
	if state.public_order < 45: pressure += 3
	if rural_attitude < -10: pressure += 2
	if state.policies.active["mobilization"] == "total": pressure += 3
	if state.policies.active["justice"] == "exemplary": pressure += 2
	var relief := 0
	if state.public_health >= 70: relief += 2
	if state.public_order >= 70: relief += 2
	if rural_attitude >= 10: relief += 2
	unrest = clampi(unrest + pressure - relief - 1, 0, 100)
	monthly_migration = _calculate_migration(state, rural_attitude)
	residents = maxi(1000, residents + monthly_migration)
	history.append({"cycle": state.calendar.cycle, "residents": residents, "migration": monthly_migration, "unrest": unrest})
	if unrest >= 75 and not rebellion_active:
		rebellion_active = true
		state.story_timeline.reports.append({"cycle": state.calendar.cycle, "title": "Открытое неповиновение", "text": "В нескольких кварталах перестали выполнять распоряжения стражи. Это уже не отдельная жалоба, а начало организованного бунта.", "read": false})
		state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "rebellion_started"})

func _calculate_migration(state: WorldState, rural_attitude: int) -> int:
	var result := 20
	result += (state.public_health - 60) * 2
	result += (state.public_order - 55)
	result += rural_attitude * 2
	if state.policies.active["mobilization"] == "total": result -= 110
	if state.policies.active["labor"] == "extended": result -= 45
	if state.policies.active["work_age"] == "twelve": result -= 35
	return clampi(result, -240, 120)

func migration_label() -> String:
	if monthly_migration > 0: return "+%d переселенцев" % monthly_migration
	if monthly_migration < 0: return "%d покинули княжество" % absi(monthly_migration)
	return "без изменений"

func to_data() -> Dictionary:
	return {"residents": residents, "monthly_migration": monthly_migration, "unrest": unrest, "rebellion_active": rebellion_active, "history": history.duplicate(true)}

func load_data(data: Dictionary) -> void:
	residents = maxi(1000, int(data.get("residents", 18400)))
	monthly_migration = int(data.get("monthly_migration", 0))
	unrest = clampi(int(data.get("unrest", 18)), 0, 100)
	rebellion_active = bool(data.get("rebellion_active", false))
	history.assign(data.get("history", []))
