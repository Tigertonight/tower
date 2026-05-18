class_name ResourcePathUtil
extends RefCounted


static func data_resource_paths(dir_path: String, extension: String = ".tres") -> Array[String]:
	var out: Array[String] = []
	var seen := {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file_name in dir.get_files():
		var normalized := _normalized_resource_file(file_name, extension)
		if normalized == "":
			continue
		if seen.has(normalized):
			continue
		seen[normalized] = true
		out.append("%s/%s" % [dir_path, normalized])
	out.sort()
	return out


static func _normalized_resource_file(file_name: String, extension: String) -> String:
	if file_name.ends_with(extension):
		return file_name
	var remap_suffix := "%s.remap" % extension
	if file_name.ends_with(remap_suffix):
		return file_name.trim_suffix(".remap")
	return ""
