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
	# The largest UI scale leaves 1280×720 in view units (user screenshot: the third card's text ran off the
	# right edge). Every card and every line on it stays on screen and inside its card, left to right too.
	root.size = Vector2i(1280, 720)
	screen._show_offer(cards, 25)
	for i in 4:
		await process_frame
	var small := Rect2(Vector2.ZERO, Vector2(root.size))
	for column in screen._cards.get_children():
		var card_button := column.get_child(0) as Button
		var card_rect := card_button.get_global_rect()
		_check(small.encloses(card_rect), "1280×720: %s fits the screen (%s)" % [_name_of(card_button), card_rect])
		for line in card_button.find_children("*", "", true, false):
			if (line is Label or line is RichTextLabel) and line.is_visible_in_tree() and line.text != "":
				var line_rect: Rect2 = line.get_global_rect()
				_check(card_rect.grow(0.5).encloses(line_rect), "1280×720: %s: \"%s\" stays inside the card (%s in %s)"
					% [_name_of(card_button), String(line.text).left(20), line_rect, card_rect])
	# Thick Blight with Wider Dreams: 5 cards, the most an offer shows (run_design.md "Omen audit fixes"), still fit
	var five: Array[UpgradeData] = [bloom, longest[0], longest[1], longest[2], longest[3]]
	screen._show_offer(five, 25)
	for i in 4:
		await process_frame
	_check(screen._cards.get_child_count() == 5, "five cards shown")
	for column in screen._cards.get_children():
		var five_button := column.get_child(0) as Button
		var five_rect := five_button.get_global_rect()
		_check(small.encloses(five_rect), "1280×720, 5 cards: %s fits the screen (%s)" % [_name_of(five_button), five_rect])
		for line in five_button.find_children("*", "", true, false):
			if (line is Label or line is RichTextLabel) and line.is_visible_in_tree() and line.text != "":
				_check(five_rect.grow(0.5).encloses(line.get_global_rect()), "1280×720, 5 cards: %s: \"%s\" stays inside the card"
					% [_name_of(five_button), String(line.text).left(20)])
	root.size = Vector2i(1280, 800)
	screen._show_offer(cards, 25)
	for i in 3:
		await process_frame
	# No Needs line on the card face (dream_design.md 2026-10-01, user: "can remove the Needs Water"), even half-dreamed
	var bloom_button := screen._cards.get_child(0).get_child(0) as Button
	var bloom_texts: Array = bloom_button.find_children("*", "", true, false) \
		.filter(func(n: Node) -> bool: return n is Label or n is RichTextLabel) \
		.map(func(n: Node) -> String: return n.text if n is Label else n.get_parsed_text())
	var joined := " | ".join(bloom_texts)
	var needs := dreams.missing_needs(bloom)
	var row := bloom_button.find_child("MissingRow", true, false)
	_check(not needs.is_empty() and row == null and not bloom_texts.any(func(t: String) -> bool: return t.begins_with("Needs"))
		and not joined.to_lower().contains("half-dreamed") and not joined.contains("Sleeps"),
		"a half-dreamed card: no \"Needs …\" line, no label (%s)" % joined)
	_check(dreams.not_active_reason(bloom) == "Not active yet: needs a %s Warden" % needs[0].type or dreams.not_active_reason(bloom).begins_with("Not active yet: needs a"),
		"…the reason lives on for the Dreams this run hover (%s)" % dreams.not_active_reason(bloom))
	_check(dreams.missing_families_text(bloom) == "Needs " + needs[0].type and needs[0].type == IconInfo.damage_type_name(needs[0].line),
		"…named by damage type, not the family (%s)" % dreams.missing_families_text(bloom))
	_check(not joined.contains("Entwined"), "no \"Entwined\" label, the vine border says it (%s)" % joined)
	# Both families owned (the user's screenshot: "Needs: Firefly Jar + Sporeling families"): no Needs line at all
	for family in ["firefly_jar", "sporeling", "bloomcap", "stormcap"]:
		dreams.unlocked[family] = true
	screen._show_offer(cards, 25)
	for i in 3:
		await process_frame
	var whole := screen._cards.get_child(0).get_child(0) as Button
	var whole_texts: Array = whole.find_children("*", "", true, false) \
		.filter(func(n: Node) -> bool: return n is Label or n is RichTextLabel) \
		.map(func(n: Node) -> String: return n.text if n is Label else n.get_parsed_text())
	_check(not whole_texts.any(func(t: String) -> bool: return t.begins_with("Needs")) and not " | ".join(whole_texts).contains("Entwined"),
		"with nothing missing the card shows no Needs line and no \"Entwined\" (%s)" % " | ".join(whole_texts))
	for family in ["sporeling", "bloomcap", "stormcap"]:
		dreams.unlocked.erase(family)
	screen._show_offer(cards, 25)
	for i in 3:
		await process_frame

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
	_check(texts.has(DreamState.OPENS_CLEARING_LINE.to_lower()) and texts.has(DreamState.OPENS_CLEARING_TEXT.to_lower()),
		"a clearing card says it unlocks clearing (%s)" % ", ".join(texts))
	_check(clear_button.find_child("OpensClearingTag", true, false) == null and texts.filter(func(t: String) -> bool: return t.contains("clearing") and t.contains("open")).is_empty(),
		"…once: the line with the Clear tool icon, no \"Opens clearing\" corner tag")
	_check(viewport.encloses(clear_button.get_global_rect()), "…and still fits the screen (%s)" % clear_button.get_global_rect())
	dreams.take(ground)
	_check(dreams.opened_clearing(ground) and not dreams.opens_clearing(ground), "once taken it opened clearing; later clearing cards don't say so")
	_check(dreams.to_save().get("clearing_opened_by") == "heartwoods_reach", "…saved with the run")
	print("longest cards: %s, %s" % [cards[1].display_name, cards[2].display_name])
	# Placement cards show a diagram (dream_design.md, user: "confusing cards like Crossroads should have a diagram"):
	# every diagram is 5 rows of 7 legend characters with a qualifying Warden and a caption; hovering Crossroads in an
	# offer shows it beside the card, on screen; leaving hides it.
	var legend := ".P+123456789WwaTXOQU*HS"
	var with_diagram := 0
	for card in dreams.pool:
		if not CardDiagram.has_diagram(card):
			continue
		with_diagram += 1
		var rows: PackedStringArray = card.diagram.strip_edges().split("
")
		var shape_ok := rows.size() == 5 and Array(rows).all(func(r: String) -> bool: return r.length() == 7)
		var chars_ok := Array(rows).all(func(r: String) -> bool:
			for ch in r:
				if not legend.contains(ch):
					return false
			return true)
		var has_hero := card.diagram.contains("W") or card.diagram.contains("Q") or card.diagram.contains("X")
		_check(shape_ok and chars_ok and has_hero and card.diagram_caption != "", "%s: a 7×5 diagram with a caption (%s)" % [card.id, card.diagram])
	_check(with_diagram >= 15, "the first set of placement cards have diagrams (%d)" % with_diagram)
	var crossroads: UpgradeData = dreams.pool.filter(func(c: UpgradeData) -> bool: return c.id == "crossroads").front()
	var diagram_offer: Array[UpgradeData] = [crossroads, longest[0], longest[1]]
	dreams.current_offer = diagram_offer
	screen._show_offer(diagram_offer, 30)
	for i in 3:
		await process_frame
	var cross_button := screen._cards.get_child(0).get_child(0) as Button
	cross_button.mouse_entered.emit()
	for i in 3:
		await process_frame
	var shown_diagram: Control = screen._diagram
	_check(shown_diagram != null and is_instance_valid(shown_diagram) and shown_diagram.visible, "hovering Crossroads shows its diagram")
	if shown_diagram != null and is_instance_valid(shown_diagram):
		var diagram_rect := shown_diagram.get_global_rect()
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(diagram_rect) and not diagram_rect.intersects(cross_button.get_global_rect()),
			"…beside the card, on screen (%s, card %s)" % [diagram_rect, cross_button.get_global_rect()])
	cross_button.mouse_exited.emit()
	_check(screen._diagram == null, "…and leaving the card hides it")
	# The living mini-scene (dream_design.md "Revised: a living mini-scene"): Heart of the Maze plays one in the pooled view
	var heart: UpgradeData = null
	for card in dreams.pool:
		if card.id == "heart_of_the_maze":
			heart = card
	if heart != null:
		var heart_offer: Array[UpgradeData] = [heart]
		dreams.current_offer = heart_offer
		screen._show_offer(heart_offer, 30)
		for i in 3:
			await process_frame
		var heart_button := screen._cards.get_child(0).get_child(0) as Button
		heart_button.mouse_entered.emit()
		var scene: CardScene = screen._scene
		_check(scene != null and scene.visible and screen._diagram == null, "Heart of the Maze: a living scene, not the still diagram")
		if scene != null:
			_check(scene._wardens.size() == 3 and scene._wardens.filter(func(w: Dictionary) -> bool: return w.boosted).size() == 1,
				"…three puppet Wardens, one of them the favoured one")
			_check(scene._path.size() == 11, "…nightmares walk the diagram's path from the start to the Heartwood (%d cells)" % scene._path.size())
			var golds := 0
			var whites := 0
			for i in 360:  # 6 s at 60 fps: the loop plays
				await process_frame
				for node in scene._world.get_children() if scene._world else []:
					if node is Label and not node.has_meta(&"counted"):
						node.set_meta(&"counted", true)
						if node.text.begins_with("×2"):
							golds += 1
						else:
							whites += 1
			_check(golds > 0 and whites > 0, "…the favoured Warden hits for gold \"×2\", the others for white numbers (%d / %d)" % [golds, whites])
			heart_button.mouse_exited.emit()
			_check(not scene.visible and not scene.is_processing() and scene._world == null, "…and leaving stops it (pooled, nothing running)")
		# The dev card grid previews it too, so it can be reviewed without waiting for a Dream to offer it
		var picker := DevCardPicker.open(screen, dreams, func(_c: UpgradeData) -> void: pass)
		picker._search.text = "Heart of the Maze"
		picker._refresh()
		await process_frame
		var grid_button: Button = picker._grid.get_child(0) if picker._grid.get_child_count() > 0 else null
		if grid_button != null:
			grid_button.mouse_entered.emit()
			await process_frame
		_check(picker._scene != null and picker._scene.visible, "the dev card grid plays Heart of the Maze's scene on hover")
		picker.queue_free()
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
