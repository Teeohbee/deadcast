# tests/test_fishing_mini.gd
extends GutTest

var fm: FishingMini

func before_each() -> void:
    fm = preload("res://scenes/dive_run/FishingMini.tscn").instantiate()
    fm.max_tension = 100
    fm.catch_stamina = 100
    fm.tension_rate = 10.0
    add_child(fm)

func after_each() -> void:
    fm.queue_free()

func test_starts_in_engaged_state() -> void:
    fm.start("Test Catch")
    assert_eq(fm.state, FishingMini.State.ENGAGED)

func test_stamina_decreases_over_time() -> void:
    fm.start("Test Catch")
    fm._process(1.0)
    assert_lt(fm.catch_stamina_current, 100.0)

func test_reel_drains_stamina_faster() -> void:
    var fm_normal = preload("res://scenes/dive_run/FishingMini.tscn").instantiate()
    fm_normal.max_tension = 100
    fm_normal.catch_stamina = 100
    fm_normal.tension_rate = 10.0
    add_child(fm_normal)
    fm_normal.start("Test")
    fm_normal._process(1.0)
    var normal_stamina = fm_normal.catch_stamina_current

    var fm_reel = preload("res://scenes/dive_run/FishingMini.tscn").instantiate()
    fm_reel.max_tension = 100
    fm_reel.catch_stamina = 100
    fm_reel.tension_rate = 10.0
    add_child(fm_reel)
    fm_reel.start("Test")
    fm_reel._reel_held = true
    fm_reel._process(1.0)
    var reel_stamina = fm_reel.catch_stamina_current

    assert_lt(reel_stamina, normal_stamina, "Reeling should drain stamina faster")
    fm_normal.queue_free()
    fm_reel.queue_free()

func test_stamina_depleted_transitions_to_reeling() -> void:
    fm.start("Test Catch")
    fm.catch_stamina_current = 1.0
    fm._process(0.5)
    assert_eq(fm.state, FishingMini.State.REELING)

func test_tension_overflow_emits_snapped() -> void:
    watch_signals(fm)
    fm.start("Test Catch")
    fm._current_tension = 99.0
    fm._process(1.0)
    assert_signal_emitted(fm, "snapped")
