class_name CampaignSaveService
extends RefCounted

const SAVE_PATH: String = "user://vertical_slice_save.json"
const AUTOSAVE_PATH: String = "user://vertical_slice_autosave.json"

static func save_campaign(state: WorldState, path: String = SAVE_PATH) -> Error:
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(state.to_data(), "\t"))
	file.close()
	if FileAccess.file_exists(path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if remove_error != OK:
			return remove_error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path))

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

static func load_latest() -> WorldState:
	var manual := load_campaign(SAVE_PATH)
	if manual != null: return manual
	return load_campaign(AUTOSAVE_PATH)

