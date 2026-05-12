class_name AscensionConfig
extends RefCounted

# Ascension difficulty mapping. Numbers are intentionally close to the StS
# pattern but tuned for our ~76 HP / ~3 cost player.
# A0 baseline.
# A1 elites HP +25%.
# A2 normals HP +10%.
# A3 bosses HP +20%, bosses damage +10%.
# A4 all enemy damage +10% (stacks with A3 on bosses).
# A5 player starts with max_hp-5 and one curse_burn in deck.

const MAX_LEVEL := 5


static func clamp_level(level: int) -> int:
	return clamp(level, 0, MAX_LEVEL)


static func enemy_hp_multiplier(level: int, tier: String) -> float:
	level = clamp_level(level)
	var mult := 1.0
	if level >= 1 and tier == "elite":
		mult *= 1.25
	if level >= 2 and tier == "normal":
		mult *= 1.10
	if level >= 3 and tier == "boss":
		mult *= 1.20
	return mult


static func enemy_damage_multiplier(level: int, tier: String) -> float:
	level = clamp_level(level)
	var mult := 1.0
	if level >= 3 and tier == "boss":
		mult *= 1.10
	if level >= 4:
		mult *= 1.10
	return mult


static func player_max_hp_penalty(level: int) -> int:
	level = clamp_level(level)
	if level >= 5:
		return 5
	return 0


static func starting_curses(level: int) -> Array[String]:
	level = clamp_level(level)
	var ids: Array[String] = []
	if level >= 5:
		ids.append("curse_burn")
	return ids


static func summary(level: int) -> String:
	level = clamp_level(level)
	if _is_zh():
		if level <= 0:
			return "A0 — 基准难度"
		var zh_lines: Array[String] = []
		if level >= 1:
			zh_lines.append("A1：精英 +25% 生命")
		if level >= 2:
			zh_lines.append("A2：普通敌人 +10% 生命")
		if level >= 3:
			zh_lines.append("A3：Boss +20% 生命，+10% 伤害")
		if level >= 4:
			zh_lines.append("A4：所有敌人 +10% 伤害")
		if level >= 5:
			zh_lines.append("A5：初始最大生命 -5，牌组加入一张灼伤")
		return "，".join(zh_lines)
	if level <= 0:
		return "A0 — baseline"
	var lines: Array[String] = []
	if level >= 1:
		lines.append("A1: Elites +25% HP")
	if level >= 2:
		lines.append("A2: Normals +10% HP")
	if level >= 3:
		lines.append("A3: Bosses +20% HP, +10% damage")
	if level >= 4:
		lines.append("A4: All enemies +10% damage")
	if level >= 5:
		lines.append("A5: Start at -5 max HP with one Burn curse")
	return ", ".join(lines)


static func _is_zh() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var loc = tree.root.get_node_or_null("/root/LocalizationManager")
	return loc != null and loc.has_method("is_zh") and loc.is_zh()
