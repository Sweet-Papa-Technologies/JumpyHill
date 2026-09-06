class_name GameInterface
extends Control
signal action(name: String, value: Variant)
const INK: Color = Color("294d4c")
const MUTED: Color = Color("728984")
const PAPER: Color = Color("fcf8e9")
const YELLOW: Color = Color("f5ce78")
const DISPLAY: Font = preload("res://assets/fonts/Bungee-Regular.ttf")
const BODY: Font = preload("res://src/ui/body_font.tres")
var game: Node
var buttons: Control
var canvas: Control
var base: Vector2 = Vector2(1440, 900)
var factor: float = 1.0
var portrait: bool = false
var page: String = "title"
var hover: String = ""
var ticker: float = 0.0
var toast: String = ""
var toast_time: float = 0.0
var safe_origin: Vector2 = Vector2.ZERO
var lean_slider: HSlider
var aim_slider: HSlider

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buttons = Control.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(buttons)
	resized.connect(rebuild)

func _process(dt: float) -> void:
	ticker += dt
	toast_time = maxf(0, toast_time - dt)
	queue_redraw()

func rebuild() -> void:
	if buttons == null or game == null:
		return
	portrait = size.x / size.y < 1.0
	base = Vector2(720, 1280) if portrait else Vector2(1440, 900)
	var safe: Rect2 = Platform.safe_area()
	factor = minf(safe.size.x / base.x, safe.size.y / base.y)
	safe_origin = safe.position + (safe.size - base * factor) / 2
	buttons.scale = Vector2.ONE * factor
	buttons.position = safe_origin
	for child: Node in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	lean_slider = null
	aim_slider = null
	var x: float = 40 if portrait else 56
	var w: float = 640 if portrait else 332
	match page:
		"title":
			button("play", "LET'S ROLL  →", Rect2(x, 1010 if portrait else 542, w, 66), YELLOW)
			button("daily", "DAILY ROLL    ↗", Rect2(x, 1090 if portrait else 624, w, 58), Color("e8eddb"))
			button("settings", "Settings", Rect2(x, 1180 if portrait else 795, 145, 44), Color.TRANSPARENT, 18)
			button("credits", "Credits", Rect2(x + 175, 1180 if portrait else 795, 140, 44), Color.TRANSPARENT, 18)
		"select":
			button("title", "←  BACK", Rect2(x, 30, 145, 42), Color.TRANSPARENT, 17)
			var yy: float = 225 if portrait else 247
			for i: int in range(8):
				var rect: Rect2 = Rect2(x + (i % 4) * (154 if portrait else 84), yy + (i / 4) * 88, 138 if portrait else 73, 74)
				button("course", "%02d" % (i + 1), rect, YELLOW if game.selected_number == i + 1 else Color("e7ecdc"), 23, i + 1)
			button("world_prev", "←", Rect2(x, 163 if portrait else 177, 44, 44), Color("e7ecdc"), 22)
			button("world_next", "→", Rect2(x + w - 44, 163 if portrait else 177, 44, 44), Color("e7ecdc"), 22)
			var unlocked: bool = Save.world_unlocked(game.selected_world)
			button("start", "ROLL THIS HILL  →" if unlocked else "EARN 4 STARS TO OPEN", Rect2(x, 1080 if portrait else 520, w, 64), YELLOW if unlocked else Color("e0e2d6"), 19, null, not unlocked)
			button("tutorial", "↗  Warm up on the tutorial hill", Rect2(x, 1170 if portrait else 613, w, 44), Color.TRANSPARENT, 18)
			button("garage", "THE TIRE SHOP   →", Rect2(x, 720 if not portrait else 995, w, 52), Color("e7ecdc"), 17)
		"aim":
			button("select", "←  HILLS", Rect2(x, 29, 145, 46), PAPER, 17)
			button("pause", "Ⅱ", Rect2(base.x - 88, 29, 48, 46), PAPER, 22)
			var yy: float = 1030 if portrait else 441
			aim_slider = slider("aim", Rect2(x, yy, w, 36), -1, 1, game.aim_value, 0.01)
			lean_slider = slider("lean", Rect2(x, yy + 95, w, 36), -15, 15, game.lean_value, 0.5)
			button("roll", "LET IT ROLL  ↓", Rect2(x, yy + 146, w, 66), YELLOW, 23)
			if portrait:
				button("purist", "PURIST ✓" if game.purist else "PURIST ○", Rect2(420, 29, 185, 46), PAPER, 18)
			if not portrait:
				button("purist", "●  PURIST" if game.purist else "○  PURIST", Rect2(x, 703, w, 45), Color("e7ecdc"), 17)
		"roll":
			button("pause", "Ⅱ", Rect2(base.x - 88, 29, 48, 46), PAPER, 22)
			var yy: float = base.y - 130
			var left: bool = Save.data.settings.left_handed
			var nx: float = 40 if portrait or left else base.x - 250
			button("nudge", "←", Rect2(nx, yy, 90, 70), PAPER, 32, -1)
			button("nudge", "→", Rect2(nx + 108, yy, 90, 70), PAPER, 32, 1)
		"result":
			var yy: float = 1000 if portrait else 519
			button("retry", "ONE MORE  ↻", Rect2(x, yy, w, 64), YELLOW, 23)
			button("new_seed", "NEW ROLL", Rect2(x, yy + 80, w * 0.48, 50), Color("e7ecdc"), 17)
			button("next", "NEXT HILL  →", Rect2(x + w * 0.52, yy + 80, w * 0.48, 50), Color("e7ecdc"), 17)
			button("share", "SAVE A POSTCARD  ↗", Rect2(x, yy + 146, w, 44), Color.TRANSPARENT, 17)
			button("select", "←  ALL HILLS", Rect2(x, 32, 170, 44), Color.TRANSPARENT, 17)
		"pause":
			button("resume", "BACK TO THE HILL  →", Rect2(x, 390, w, 64), YELLOW, 21)
			button("settings", "Settings", Rect2(x, 477, w, 54), Color("e7ecdc"))
			button("select", "Choose another hill", Rect2(x, 551, w, 54), Color("e7ecdc"))
		"settings":
			button("settings_back", "←  BACK", Rect2(x, 30, 145, 44), Color.TRANSPARENT, 17)
			for i: int in range(3):
				var key: String = ["master", "music", "sfx"][i]
				slider(key, Rect2(x, 215 + i * 90, w, 34), 0, 1, Save.data.settings[key], 0.01)
			for i: int in range(4):
				var key: String = ["haptics", "left_handed", "reduce_motion", "colorblind"][i]
				var names: Array[String] = ["Haptics", "Left-handed", "Reduce motion", "Patterned goal markers"]
				button("setting_toggle", "%s    %s" % [names[i], "ON" if Save.data.settings[key] else "OFF"], Rect2(x, 495 + i * 60, w, 46), Color("e7ecdc"), 18, key)
		"credits":
			button("title", "←  BACK", Rect2(x, 30, 145, 44), Color.TRANSPARENT, 17)
		"garage":
			button("select", "←  HILLS", Rect2(x, 30, 145, 44), Color.TRANSPARENT, 17)
			for i: int in range(4):
				var td: TireData = load("res://src/tire/%d.tres" % i) as TireData
				var unlocked: bool = Save.stars_total() >= td.unlock_stars
				button("tire", "%s   %s" % [td.title, "✓" if Save.data.tire == i else ("→" if unlocked else "%d ★" % td.unlock_stars)], Rect2(x, 245 + i * 95, w, 70), td.accent if unlocked else Color("e2e5da"), 23, i, not unlocked)
	queue_redraw()

func button(key: String, label: String, rect: Rect2, color: Color, font_size: int = 21, value: Variant = null, disabled: bool = false) -> Button:
	var b: Button = Button.new()
	b.name = key + "_" + str(value)
	b.text = tr(label)
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.disabled = disabled
	b.add_theme_font_override("font", BODY)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = color.lightened(0.06) if state == "hover" else color
		if state == "pressed":
			style.bg_color = color.darkened(0.07)
		style.corner_radius_top_left = 13
		style.corner_radius_top_right = 13
		style.corner_radius_bottom_left = 13
		style.corner_radius_bottom_right = 13
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.set_border_width_all(2)
			style.border_color = INK
		b.add_theme_stylebox_override(state, style)
	b.pressed.connect(func() -> void: Sound.play("click"); action.emit(key, value))
	buttons.add_child(b)
	return b

func slider(key: String, rect: Rect2, low: float, high: float, value: float, step_value: float) -> HSlider:
	var s: HSlider = HSlider.new()
	s.name = key
	s.position = rect.position
	s.size = rect.size
	s.min_value = low
	s.max_value = high
	s.step = step_value
	s.value = value
	s.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	s.value_changed.connect(func(v: float) -> void: action.emit(key, v))
	buttons.add_child(s)
	return s

func label(text: String, pos: Vector2, font_size: int = 22, color: Color = INK, display: bool = false) -> void:
	draw_string(DISPLAY if display else BODY, pos, tr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func panel(rect: Rect2, color: Color, radius: int = 24) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func _draw() -> void:
	if game == null:
		return
	draw_set_transform(safe_origin, 0, Vector2.ONE * factor)
	var x: float = 40 if portrait else 56
	var w: float = 640 if portrait else 332
	var hud: bool = page in ["aim", "roll"]
	if not portrait:
		panel(Rect2(24, 24, 396, base.y - 48), PAPER, 25)
	else:
		if page == "title":
			panel(Rect2(20, 25, 680, 353), PAPER, 25)
			panel(Rect2(20, 979, 680, 275), PAPER, 25)
		elif page in ["aim", "roll"]:
			panel(Rect2(20, 20, 680, 175), PAPER, 22)
			if page == "aim":
				panel(Rect2(20, 958, 680, 300), PAPER, 22)
		elif page in ["select", "result"]:
			panel(Rect2(20, 20, 680, 435 if page == "select" else 440), PAPER, 25)
			panel(Rect2(20, 976, 680, 278), PAPER, 25)
		else:
			panel(Rect2(20, 20, 680, 1235), PAPER, 25)
	match page:
		"title":
			label("SWEET PAPA PRESENTS", Vector2(x, 98 if not portrait else 80), 15, MUTED)
			label("TREAD", Vector2(x - 3, 221 if not portrait else 178), 69, INK, true)
			label("FALL", Vector2(x - 3, 298 if not portrait else 258), 86, INK, true)
			label("GOOD HILLS. GREAT ROLLS.", Vector2(x, 349 if not portrait else 313), 16, MUTED)
			if not portrait:
				draw_line(Vector2(x, 385), Vector2(x + w, 385), Color("d8dfce"), 1)
				label("Read the hill.", Vector2(x, 435), 29)
				label("Find your line. Let it roll.", Vector2(x, 475), 25)
				label("33 HILLS  /  4 WORLDS  /  ONE TIRE", Vector2(x, 746), 13, MUTED)
		"select":
			label("PICK YOUR", Vector2(x, 115), 34, INK, true)
			label("HAPPY PLACE.", Vector2(x, 155), 31, INK, true)
			label(CourseData.WORLDS[game.selected_world], Vector2(x + 58, 194 if portrait else 208), 22)
			if not portrait:
				label(game.course.data.title.to_upper(), Vector2(x, 466), 21, INK, true)
				label("%d m  /  %s  /  %d STYLE PAR" % [game.course.data.length, "MOVING GATE" if game.course.data.moving_gate else "OPEN GATE", game.course.data.par_style], Vector2(x, 493), 12, MUTED)
			label("%d ★ COLLECTED" % Save.stars_total(), Vector2(x, 840 if not portrait else 955), 16, MUTED)
			for i: int in range(8):
				var id_v: String = "%s/%02d" % [CourseData.SLUGS[game.selected_world], i + 1]
				var stars: int = int(Save.data.courses.get(id_v, {}).get("stars", 0))
				if stars > 0:
					label("★".repeat(stars), Vector2(x + (i % 4) * (154 if portrait else 84) + 12, (225 if portrait else 247) + (i / 4) * 88 + 71), 12)
		"aim", "roll":
			label("%s  /  %02d" % [CourseData.WORLDS[game.course.data.world].to_upper(), game.course.data.number], Vector2(x, 116 if portrait else 146), 14, MUTED)
			label(game.course.data.title.to_upper(), Vector2(x, 159 if portrait else 188), 27, INK, true)
			if page == "aim":
				if not portrait:
					label("PICK YOUR LINE.", Vector2(x, 285), 24, INK, true)
					label("DODGE. BANK. COMMIT.", Vector2(x, 318), 20, INK, true)
					label("Drag to aim. Lift to roll.", Vector2(x, 365), 22, MUTED)
				var yy: float = 1020 if portrait else 426
				label("LAUNCH ANGLE", Vector2(x, yy), 15, MUTED)
				label("%+.0f°" % (game.aim_value * 25), Vector2(x + w - 57, yy), 17)
				label("BANK / DRIFT", Vector2(x, yy + 95), 15, MUTED)
				label("%+.1f°" % game.lean_value, Vector2(x + w - 64, yy + 95), 17)
				if not portrait:
					label("← → AIM    ↑ ↓ LEAN    SPACE ROLL", Vector2(x, 793), 12, MUTED)
					label("Short guide. Two nudges. No autopilot.", Vector2(x, 824), 17, MUTED)
			else:
				if not portrait:
					label("LET THE", Vector2(x, 282), 36, INK, true)
					label("GOOD TIMES", Vector2(x, 324), 32, INK, true)
					label("ROLL.", Vector2(x, 380), 55, INK, true)
					label("%03d" % game.tire.style.score, Vector2(x, 509), 68, INK, true)
					label("STYLE POINTS", Vector2(x, 539), 15, MUTED)
					panel(Rect2(x, 573, w, 10), Color("e2e6d7"), 5)
					panel(Rect2(x, 573, maxf(12, w * minf(1, game.tire.style.score / 300.0)), 10), YELLOW, 5)
					label("×%d  COMBO" % game.tire.style.combo, Vector2(x, 626), 25, INK, true)
					label("%.1f m/s" % game.tire.linear_velocity.length(), Vector2(x, 740), 28)
					label("%s" % ("PURIST" if game.purist else ("TILT — LOCKED" if game.tire.tilted else "%d NUDGES LEFT" % (2 - game.tire.nudges))), Vector2(x, 797), 18, MUTED)
				else:
					label("%d STYLE    ×%d" % [game.tire.style.score, game.tire.style.combo], Vector2(365, 63), 18)
		"result":
			var good: bool = game.result.get("outcome", "") == "GOAL"
			label("SIGNED, SEALED," if good else "READ THE HILL.", Vector2(x, 148), 23, MUTED, true)
			label("DELIVERED." if good else ("ROADBLOCK." if game.result.get("outcome") == "BLOCKED" else "ANOTHER LINE."), Vector2(x, 206), 35, INK, true)
			label("★".repeat(int(game.result.get("stars", 0))) + "☆".repeat(3 - int(game.result.get("stars", 0))), Vector2(x, 280), 52, Color("c1943f"))
			label("%03d" % game.result.get("score", 0), Vector2(x, 365), 62, INK, true)
			label("STYLE POINTS", Vector2(x + 180, 350), 14, MUTED)
			if portrait:
				panel(Rect2(20, 928, 680, 48), PAPER, 16)
				label("%s  ·  SEED %d" % [game.course.data.title, game.roll_seed], Vector2(x, 960), 18, MUTED)
			label("%s  /  %.1f SECONDS" % [game.result.get("outcome", "WIDE"), game.result.get("time", 0)], Vector2(x, 408), 16)
			if not portrait:
				var feedback: String = "CENTER %d%%" % roundi(float(game.result.get("accuracy", 0)) * 100)
				if not good:
					feedback = "Aim around it. Bank back toward goal." if game.result.get("outcome") == "BLOCKED" else ("Try less bank to stay on the hill." if game.tire.position.z < game.course.data.length - 2 else "%.1f tire widths from the center" % (float(game.result.get("offset", 0)) / 1.3))
				label(feedback, Vector2(x, 450), 16, MUTED)
				label("SEED  %d" % game.roll_seed, Vector2(x, 785), 14, MUTED)
				label("Same hill. A whole new possibility.", Vector2(x, 818), 17, MUTED)
		"pause":
			label("TAKE A", Vector2(x, 213), 44, INK, true)
			label("BREATHER.", Vector2(x, 268), 39, INK, true)
			label("Your hill will be right here.", Vector2(x, 330), 22, MUTED)
		"settings":
			label("YOUR KIND", Vector2(x, 123), 31, INK, true)
			label("OF ROLL.", Vector2(x, 163), 35, INK, true)
			for i: int in range(3):
				label(["MASTER", "MUSIC", "SOUND EFFECTS"][i], Vector2(x, 204 + i * 90), 15, MUTED)
			label("LANGUAGE   ENGLISH", Vector2(x, 796), 15, MUTED)
		"garage":
			label("PICK YOUR", Vector2(x, 141), 34, INK, true)
			label("PERSONALITY.", Vector2(x, 186), 31, INK, true)
			label("Earn stars. Find a new favorite.", Vector2(x, 699), 21, MUTED)
			label("%d ★ COLLECTED" % Save.stars_total(), Vector2(x, 748), 19)
		"credits":
			label("MADE FOR", Vector2(x, 144), 33, INK, true)
			label("ONE MORE.", Vector2(x, 190), 35, INK, true)
			var lines: Array[String] = ["TREADFALL / 0.2", "Sweet Papa Technologies", "Forrester ‘FoFo’ Terry", "", "BUILT WITH GODOT 4.7.2 · MIT", "Nature & impact sounds: Kenney · CC0", "Bungee: David Jonathan Ross · OFL", "Nunito: Vernon Adams et al. · OFL", "Original procedural hills & synth music", "", "No ads. No accounts. Just good hills.", "Asset licenses included with the game."]
			for i: int in range(lines.size()):
				label(lines[i], Vector2(x, 276 + i * 36), 16 if i > 3 else 21, MUTED if i > 3 else INK)
	if not portrait:
		panel(Rect2(460, 32, 278, 42), Color(PAPER, 0.85), 21)
		label("●  " + CourseData.WORLDS[game.course.data.world].to_upper(), Vector2(480, 59), 15)
		label("THE DOWNHILL SOCIAL CLUB", Vector2(base.x - 310, base.y - 40), 13, Color(INK, 0.7))
	if page == "roll" and game.pop_time > 0:
		var px: float = 170 if portrait else 760
		label(game.pop_text, Vector2(px, base.y * 0.33), 48, Color("fff3cf"), true)
	if toast_time > 0:
		panel(Rect2(base.x / 2 - 260, 88, 520, 55), INK, 16)
		label(toast, Vector2(base.x / 2 - 240, 123), 18, PAPER)
	if hud and not Save.data.settings.reduce_motion and page == "roll" and game.tire.linear_velocity.length() > game.course.data.max_speed * 0.8:
		for i: int in range(12):
			var center: Vector2 = Vector2(base.x * (0.5 if portrait else 0.7), base.y * 0.5)
			var angle: float = i * TAU / 12 + 0.1
			var dir: Vector2 = Vector2(cos(angle), sin(angle))
			draw_line(center + dir * base.y * 0.44, center + dir * base.y * 0.65, Color(1, 1, 0.92, 0.16), 2)
	draw_set_transform(Vector2.ZERO)
