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
	file.flush()
	var write_error := file.get_error()
	file.close()
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	if write_error != OK:
		DirAccess.remove_absolute(temporary_absolute)
		return write_error
	var rename_error := DirAccess.rename_absolute(temporary_absolute, ProjectSettings.globalize_path(path))
	if rename_error != OK:
		DirAccess.remove_absolute(temporary_absolute)
	return rename_error

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

static func load_latest(save_path: String = SAVE_PATH, autosave_path: String = AUTOSAVE_PATH) -> WorldState:
	var manual := load_campaign(save_path)
	if manual != null: return manual
	return load_campaign(autosave_path)

