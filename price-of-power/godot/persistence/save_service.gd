class_name CampaignSaveService
extends RefCounted

const SAVE_PATH: String = "user://vertical_slice_save.json"

static func save_campaign(state: WorldState, path: String = SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(state.to_data(), "\t"))
	file.close()
	return OK

static func load_campaign(path: String = SAVE_PATH) -> WorldState:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return null
	var data := parsed as Dictionary
	if int(data.get("version", -1)) != WorldState.SAVE_VERSION:
		return null
	return WorldState.from_data(data)

