class_name KeywordCatalog
extends RefCounted

# Centralized definitions for status / mechanic keywords surfaced in the HUD,
# card text, relic descriptions, and the KeywordInspector tooltip.
#
# Each entry is keyed by the lowercased keyword id used in code (e.g.
# `statuses["vulnerable"]`, "weak", "ink", "block"). Display names are how the
# tooltip header reads.
#
# To add a new keyword:
#   1) Add an entry below.
#   2) Make sure any in-game text uses the same lowercased id, so the inspector
#      can match it (the inspector lower-cases input).
#   3) Optional: produce an icon at `res://art/generated/icons/status_<id>.png`
#      (see tower/29_art_assets_required.md).
#
# Order is mostly stable; tooltips are looked up by id so it doesn't matter at
# runtime, but UI rows render in this order when iterating.

const ENTRIES: Array[Dictionary] = [
	{
		"id": "block",
		"display": "Block",
		"category": "defense",
		"summary": "Absorbs incoming damage. Resets to 0 at the start of your turn unless a relic preserves it.",
	},
	{
		"id": "strength",
		"display": "Strength",
		"category": "buff",
		"summary": "Each stack adds +1 damage to every Attack you play. Permanent until the end of combat.",
	},
	{
		"id": "dexterity",
		"display": "Dexterity",
		"category": "buff",
		"summary": "Each stack adds +1 Block to every Block you gain from a card. Permanent until the end of combat.",
	},
	{
		"id": "vulnerable",
		"display": "Vulnerable",
		"category": "debuff",
		"summary": "The target takes 50% more damage from Attacks. Decreases by 1 at the end of the afflicted's turn.",
	},
	{
		"id": "weak",
		"display": "Weak",
		"category": "debuff",
		"summary": "The target deals 25% less damage from Attacks. Decreases by 1 at the end of the afflicted's turn.",
	},
	{
		"id": "frail",
		"display": "Frail",
		"category": "debuff",
		"summary": "The target gains 25% less Block from cards. Decreases by 1 at the end of the afflicted's turn.",
	},
	{
		"id": "ink",
		"display": "Ink",
		"category": "dot",
		"summary": "At the end of the afflicted's turn, takes damage equal to its Ink stacks (bypasses Block), then loses 1 Ink. The Archivist's signature mechanic.",
	},
	{
		"id": "energy",
		"display": "Energy",
		"category": "resource",
		"summary": "Resource spent to play cards. Refills at the start of every turn.",
	},
	{
		"id": "exhaust",
		"display": "Exhaust",
		"category": "card_keyword",
		"summary": "When played, the card is removed from your deck for the rest of the combat instead of going to the discard pile.",
	},
	{
		"id": "retain",
		"display": "Retain",
		"category": "card_keyword",
		"summary": "This card is not discarded at the end of your turn — it stays in hand for next turn.",
	},
	{
		"id": "innate",
		"display": "Innate",
		"category": "card_keyword",
		"summary": "Always part of your opening hand on the first turn of every combat.",
	},
	{
		"id": "ethereal",
		"display": "Ethereal",
		"category": "card_keyword",
		"summary": "If still in your hand at the end of your turn, this card is Exhausted.",
	},
	{
		"id": "intent",
		"display": "Intent",
		"category": "ui",
		"summary": "The icon next to an enemy showing its next move: attack, block, buff, or debuff.",
	},
	{
		"id": "phase_shift",
		"display": "Phase Shift",
		"category": "boss",
		"summary": "When a boss drops below a HP threshold, it shifts into a more dangerous state — gaining stats and switching to a new move pool.",
	},
]


static func entries() -> Array[Dictionary]:
	return ENTRIES


static func get_entry(id: String) -> Dictionary:
	if id == "":
		return {}
	var lid := id.to_lower()
	for entry in ENTRIES:
		if String(entry.get("id", "")) == lid:
			return entry
	return {}


static func describe(id: String) -> String:
	var entry := get_entry(id)
	if entry.is_empty():
		return ""
	return "%s — %s" % [String(entry.get("display", id)), String(entry.get("summary", ""))]
