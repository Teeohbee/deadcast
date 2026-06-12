# tests/test_zone_data.gd
extends GutTest

func test_district7_display_fields() -> void:
	var z: ZoneData = load("res://resources/zones/district7.tres")
	assert_eq(z.tag_label, "CIVILIAN")
	assert_eq(z.tag_tier, 0)
	assert_eq(z.density, "64%")
	assert_eq(z.threat, "LOW")

func test_exchange_display_fields() -> void:
	var z: ZoneData = load("res://resources/zones/exchange.tres")
	assert_eq(z.tag_label, "BLACK MARKET")
	assert_eq(z.tag_tier, 1)
	assert_eq(z.density, "81%")
	assert_eq(z.threat, "MID")

func test_axiom_display_fields() -> void:
	var z: ZoneData = load("res://resources/zones/axiom.tres")
	assert_eq(z.tag_label, "CORPORATE SECURE")
	assert_eq(z.tag_tier, 2)
	assert_eq(z.density, "95%")
	assert_eq(z.threat, "HIGH")

func test_zone_interference_loads_from_tres() -> void:
	var axiom: ZoneData = load("res://resources/zones/axiom.tres")
	assert_eq(axiom.zone_interference, 5)
	var d7: ZoneData = load("res://resources/zones/district7.tres")
	assert_eq(d7.zone_interference, 0)
