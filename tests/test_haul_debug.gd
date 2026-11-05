extends GutTest
# The haul debug scene (dev tool): plays any real hauled contact on its own.

func _scene() -> Node:
	var s: Node = load("res://scenes/dive_run/haul/HaulDebug.tscn").instantiate()
	add_child_autofree(s)
	return s

func test_it_plays_real_contacts_from_every_zone() -> void:
	var s := _scene()
	var zones := {}
	for e in s.entries:
		assert_true(e.catch.haul_enabled, e.catch.catch_name)
		assert_true(HaulTurn.hauls(e.catch, e.option), e.catch.catch_name + " / " + e.option.label)
		zones[e.zone] = true
	assert_eq(zones.size(), 3, "district7, exchange and axiom")

func test_stepping_contacts_and_options_restarts_the_haul() -> void:
	var s := _scene()
	var first: HaulRun = s.run
	s.step_contact(1)
	await wait_process_frames(1)
	assert_ne(s.run, first)
	assert_eq(s.run.get_parent(), s)
	var before: Dictionary = s.current()
	s.step_option()
	assert_true(s.current().catch == before.catch, "same contact, next option")
