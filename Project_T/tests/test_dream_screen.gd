extends SceneTree

# Headless layout test for the Dream screen (screens_ui.md "Choice screens"): with the longest cards
# at 1280×800, every card's text stays inside its card, the cards share one height and fit the screen,
# and the effect text comes right after the name. Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_dream_screen.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var screen = main.get_node("HUD/DreamScreen")
	root.size = Vector2i(1280, 800)

	# Charged Bloom half-dreamed (the user's screenshot: Entwined + Half-dreamed lines) and the two
	# cards with the longest text.
	dreams.unlocked["firefly_jar"] = true
	dreams.grove_cards.assign(dreams.pool.map(func(c: UpgradeData) -> String: return c.id))
	dreams._offer_drift = 10
	var bloom: UpgradeData = null
	for card in dreams.pool:
		if card.id == "static_bloom":
			bloom = card
	_check(bloom != null and dreams.is_half_dreamed(bloom), "Charged Bloom is half-dreamed here")
	var longest: Array = dreams.pool.filter(func(c: UpgradeData) -> bool:
		return c != bloom and c.kind != UpgradeData.Kind.UNLOCK_EVOLUTION and c.kind != UpgradeData.Kind.UNLOCK_WARDEN)
	longest.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool: return _text_length(a) > _text_length(b))
	var cards: Array[UpgradeData] = [bloom, longest[0], longest[1]]
	dreams.current_offer = cards
	screen._show_offer(cards, 25)
	for i in 4:
		await process_frame

	var viewport := Rect2(Vector2.ZERO, Vector2(root.size))
	var heights := {}
	for column in screen._cards.get_children():
		var button := column.get_child(0) as Button
		var rect := button.get_global_rect()
		heights[roundi(rect.size.y)] = true
		_check(viewport.encloses(rect), "%s fits the screen (%s)" % [_name_of(button), rect])
		var box := button.get_child(0) as Control
		var labels := box.get_children().filter(func(n: Node) -> bool: return n is Label or n is RichTextLabel or n is HBoxContainer)  # The rarity row is gem + label
		for label in labels:
			var label_rect: Rect2 = label.get_global_rect()
			_check(label_rect.end.y <= rect.end.y + 0.5 and label_rect.position.y >= rect.position.y,
				"%s: a line stays inside the card (%s in %s)" % [_name_of(button), label_rect, rect])
		# Rarity row, name, then the effect (a RichTextLabel with the card's description)
		_check(labels.size() >= 3 and labels[2] is RichTextLabel, "%s: the effect comes right after the name" % _name_of(button))
	_check(heights.size() == 1, "all cards share one height (%s)" % heights.keys())
	# Half-dreamed stays internal: the card shows only "Needs <damage type>" (no emblem), no label, no "Sleeps"
	var bloom_button := screen._cards.get_child(0).get_child(0) as Button
	var bloom_texts: Array = bloom_button.find_children("*", "", true, false) \
		.filter(func(n: Node) -> bool: return n is Label or n is RichTextLabel) \
		.map(func(n: Node) -> String: return n.text if n is Label else n.get_parsed_text())
	var joined := " | ".join(bloom_texts)
	var needs := dreams.missing_needs(bloom)
	var row := bloom_button.find_child("MissingRow", true, false)
	_check(not needs.is_empty() and row != null and bloom_texts.has(needs[0].type) and row.get_children().filter(func(c: Node) -> bool: return c is TextureRect).is_empty()
		and not joined.to_lower().contains("half-dreamed") and not joined.contains("Sleeps"),
		"a half-dreamed card: one \"Needs <type>\" line, no emblem (%s)" % joined)
	_check(dreams.missing_families_text(bloom) == "Needs " + needs[0].type and needs[0].type == IconInfo.damage_type_name(needs[0].line),
		"…named by damage type, not the family (%s)" % dreams.missing_families_text(bloom))

	# Make the clearing unlock obvious: while clearing is locked, a clearing card leads with it.
	dreams.clearing_open = false
	dreams.stacks.clear()
	var ground: UpgradeData = dreams.pool.filter(func(c: UpgradeData) -> bool: return c.id == "heartwoods_reach").front()
	var clear_cards: Array[UpgradeData] = [ground, longest[0], longest[1]]
	dreams.current_offer = clear_cards
	screen._show_offer(clear_cards, 25)
	for i in 4:
		await process_frame
	var clear_button := screen._cards.get_child(0).get_child(0) as Button
	var texts: Array = clear_button.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text.to_lower())  # Small caps lower the text
	_check(texts.has(DreamState.OPENS_CLEARING_LINE.to_lower()) and texts.has(DreamState.OPENS_CLEARING_TEXT.to_lower()) and texts.has(DreamState.OPENS_CLEARING_TAG.to_lower()),
		"a clearing card says it unlocks clearing (%s)" % ", ".join(texts))
	_check(viewport.encloses(clear_button.get_global_rect()), "…and still fits the screen (%s)" % clear_button.get_global_rect())
	dreams.take(ground)
	_check(dreams.opened_clearing(ground) and not dreams.opens_clearing(ground), "once taken it opened clearing; later clearing cards don't say so")
	_check(dreams.to_save().get("clearing_opened_by") == "heartwoods_reach", "…saved with the run")
	print("longest cards: %s, %s" % [cards[1].display_name, cards[2].display_name])
	print("dream screen test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

static func _text_length(card: UpgradeData) -> int:
	return card.description.length() + card.cost_description.length() + 30 * card.requires.size()

static func _name_of(button: Button) -> String:
	var box := button.get_child(0)
	return box.get_child(1).text if box.get_child_count() > 1 else "card"

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
