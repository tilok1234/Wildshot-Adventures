extends PanelContainer
## Death recap panel (docs/12 §2.10, Law 8: every death explainable).
## Shown on player death over the frozen sim: killing pattern + damage,
## telegraph lead time, and the last-5-seconds hit trace. Restart is the
## scenario_reset action (default T).

## Pattern id -> display name (ui-side lookup; EnemyDefs extend at M5).
const PATTERN_NAMES := {
	1: "Longbolt",
	2: "Scattercast",
	3: "Wheelblade",
	100: "Debug Ring",
	-1: "Nova Burst",
	-2: "Blast Rune",
}

var _label := Label.new()


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(_label)


func show_recap(recap: Dictionary, reset_key: String) -> void:
	var lines: Array[String] = ["YOU DIED"]
	var killer: Dictionary = recap.killer
	if not killer.is_empty():
		var name := String(
			PATTERN_NAMES.get(int(killer.pattern), "pattern %d" % int(killer.pattern))
		)
		var lead := int(recap.telegraph_lead_ticks)
		var lead_txt := "  (telegraphed %.1fs before)" % (lead / 60.0) if lead >= 0 else ""
		lines.append("killed by %s, %d dmg%s" % [name, int(killer.amount), lead_txt])
	var trace: Array = recap.trace
	lines.append("last 5s: %d hit(s)" % trace.size())
	var start := maxi(0, trace.size() - 8)
	for i in range(start, trace.size()):
		var h: Dictionary = trace[i]
		var ago := (int(recap.death_tick) - int(h.tick)) / 60.0
		(
			lines
			. append(
				(
					"  -%.1fs  %s  %d dmg"
					% [
						ago,
						String(PATTERN_NAMES.get(int(h.pattern), "?")),
						int(h.amount),
					]
				)
			)
		)
	lines.append("")
	lines.append("[%s] restart (new seed)" % reset_key)
	_label.text = "\n".join(lines)
	visible = true
