extends RefCounted

const OPTIONS := {
	"guarantee": "Предложить письменные гарантии для возвращения",
	"listen": "Спросить, что нужно семье, оставив решение о возвращении Аделе"
}

static func terms(state: WorldState) -> Dictionary:
	if state.calendar.is_demo_complete() or state.facts.has("family_letter"):
		return {}
	var security := str(state.facts.get("family_security", ""))
	if security not in ["country_cloister", "breached"]:
		return {}
	var case_record: Dictionary = state.story_timeline.resolved.get("family_warning", {})
	if state.calendar.cycle <= int(case_record.get("cycle", 11)):
		return {}
	var context := "Адела с детьми за городом. Она передала через Ладу письмо: «Всеволод спрашивает, сможет ли вернуться к своим урокам. Я согласна обсуждать это, если ты объяснишь, кому теперь подчиняется караул у детской»."
	if security == "breached":
		context = "Лада привезла письмо от Аделы и пообещала ей не раскрывать укрытие. «Я увезла детей, когда не получила ответа на свой вопрос об охране. Если тебе важно их вернуть, сначала выслушай меня»."
	return {"title": "Письмо из-за городских стен", "context": context, "options": OPTIONS}

static func choose(state: WorldState, choice_id: String) -> String:
	if terms(state).is_empty() or not OPTIONS.has(choice_id) or not state.can_govern():
		return ""
	state.facts["family_letter"] = choice_id
	state.facts["family_letter_due"] = state.calendar.cycle + 1
	state.add_fatigue(1)
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "family_letter_sent", "choice": choice_id})
	if choice_id == "guarantee":
		return "Вы перечислили, какие записи караула проверит совет. Лада забрала письмо и попросила оставить внизу место для условий Аделы."
	return "Вы попросили Ладу узнать, что сейчас нужно детям, и передать, что не будете требовать их возвращения. Место укрытия не внесли в книгу исходящих писем."

static func update(state: WorldState) -> void:
	var due := int(state.facts.get("family_letter_due", 0))
	if due == 0:
		if state.facts.get("family_letter_reply") == "awaiting_guards" and _arrangements_checked(state):
			_confirm_review(state, "Лада передала Аделе выписку о том, кто теперь проверяет караулы. Адела попросила прислать книгу смен своему свидетелю. Дети останутся за городом до его отчёта.")
		return
	if state.calendar.cycle < due:
		return
	state.facts.erase("family_letter_due")
	var spouse := state.characters["spouse"] as CharacterState
	var result := ""
	if state.facts.get("family_letter") == "guarantee":
		if _arrangements_checked(state):
			_confirm_review(state, "Адела согласилась прислать своего человека на проверку караула. До его отчёта дети останутся за городом. Она просит показать ему ту же книгу смен, которую видят княжеские советники.")
			return
		else:
			state.facts["family_letter_reply"] = "awaiting_guards"
			spouse.remember(state.calendar.cycle, "family_letter", "Вы дали гарантии, но ей ещё нечем их проверить.", {"respect": 1})
			result = "Адела вернула лист с одной припиской: «Кто назовёт дежурных по именам, если я спрошу не у тебя?» Пока нет проверяемой книги караулов, она остаётся с детьми за городом."
	else:
		state.facts["family_letter_reply"] = "trust_through_lada"
		spouse.remember(state.calendar.cycle, "family_letter", "Вы оставили за ней решение о возвращении и попросили выслушать её.", {"trust": 4})
		result = "Лада передала просьбу о тетрадях и зимних сапогах. Адела согласна переписываться через неё. Она вспомнила, что незнакомец появлялся, пока двое сменщиков спорили у кухни: эту смену можно сверить в книге караулов."
	state.story_timeline.reports.append({"cycle": state.calendar.cycle, "title": "Адела ответила на письмо", "text": result, "read": false})

static func _arrangements_checked(state: WorldState) -> bool:
	return state.facts.get("command_structure") == "joint" or state.facts.get("new_rule") == "public_law"

static func _confirm_review(state: WorldState, result: String) -> void:
	state.facts["family_letter_reply"] = "ready_to_discuss"
	var spouse := state.characters["spouse"] as CharacterState
	spouse.remember(state.calendar.cycle, "family_guard_review", "Вы прислали условия возвращения, которые можно проверить по книгам.", {"trust": 3, "respect": 2})
	state.story_timeline.reports.append({"cycle": state.calendar.cycle, "title": "Адела согласна на проверку караула", "text": result, "read": false})
