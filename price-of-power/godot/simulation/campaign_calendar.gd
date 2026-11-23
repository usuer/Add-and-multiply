class_name CampaignCalendar
extends Resource

enum Period { BEGINNING, MIDDLE, END }

const MONTH_NAMES: Array[String] = [
	"Март", "Апрель", "Май", "Июнь", "Июль", "Август"
]

@export var year: int = 1248
@export var month_index: int = 0
@export var period: Period = Period.BEGINNING
@export var cycle: int = 1

func advance() -> bool:
	if is_demo_complete():
		return false
	cycle += 1
	if period == Period.END:
		period = Period.BEGINNING
		month_index += 1
	else:
		period = (period + 1) as Period
	return true

func is_demo_complete() -> bool:
	return month_index >= MONTH_NAMES.size()

func period_name() -> String:
	match period:
		Period.BEGINNING: return "Начало месяца"
		Period.MIDDLE: return "Середина месяца"
		Period.END: return "Конец месяца"
	return "Неизвестный период"

func display_date() -> String:
	if is_demo_complete():
		return "Эпилог · %d" % year
	return "%s %d · %s" % [MONTH_NAMES[month_index], year, period_name()]

func to_data() -> Dictionary:
	return {"year": year, "month_index": month_index, "period": int(period), "cycle": cycle}

func load_data(data: Dictionary) -> void:
	year = int(data.get("year", 1248))
	month_index = clampi(int(data.get("month_index", 0)), 0, MONTH_NAMES.size())
	period = clampi(int(data.get("period", 0)), 0, Period.size() - 1) as Period
	cycle = maxi(1, int(data.get("cycle", 1)))

