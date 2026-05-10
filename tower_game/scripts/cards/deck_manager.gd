class_name DeckManager
extends RefCounted

var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var max_hand_size := 10


func setup(deck: Array) -> void:
	draw_pile = deck.duplicate()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	draw_pile.shuffle()


func draw_cards(count: int) -> Array:
	var drawn: Array = []
	for i in count:
		if hand.size() >= max_hand_size:
			break
		if draw_pile.is_empty():
			_shuffle_discard_into_draw()
		if draw_pile.is_empty():
			break
		var card = draw_pile.pop_back()
		hand.append(card)
		drawn.append(card)
	return drawn


func discard(card) -> void:
	if hand.has(card):
		hand.erase(card)
		discard_pile.append(card)


func exhaust(card) -> void:
	if hand.has(card):
		hand.erase(card)
		exhaust_pile.append(card)


func discard_hand() -> void:
	while not hand.is_empty():
		discard_pile.append(hand.pop_back())


func _shuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
