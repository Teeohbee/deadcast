# tests/test_line_system.gd
extends GutTest

var ls: LineSystem

func before_each() -> void:
    ls = LineSystem.new()
    ls.max_tension = 100

func after_each() -> void:
    ls.free()

func test_tension_starts_at_zero() -> void:
    assert_eq(ls.tension, 0.0)

func test_apply_tension_increases_value() -> void:
    ls.apply_tension(20)
    assert_eq(ls.tension, 20.0)

func test_tension_clamps_at_max() -> void:
    ls.apply_tension(200)
    assert_eq(ls.tension, 100.0)

func test_apply_tension_emits_tension_updated() -> void:
    watch_signals(ls)
    ls.apply_tension(10)
    assert_signal_emitted(ls, "tension_updated")

func test_snap_emits_when_tension_hits_max() -> void:
    watch_signals(ls)
    ls.apply_tension(100)
    assert_signal_emitted(ls, "snapped")

func test_reduce_tension_decreases_value() -> void:
    ls.apply_tension(50)
    ls.apply_tension(-20)
    assert_eq(ls.tension, 30.0)

func test_tension_cannot_go_below_zero() -> void:
    ls.apply_tension(-50)
    assert_eq(ls.tension, 0.0)

func test_corruption_starts_at_zero() -> void:
    assert_eq(ls.corruption, 0.0)

func test_add_corruption_increases_value() -> void:
    ls.add_corruption(30)
    assert_eq(ls.corruption, 30.0)

func test_corruption_clamps_at_100() -> void:
    ls.add_corruption(200)
    assert_eq(ls.corruption, 100.0)

func test_reset_tension_clears_tension_but_keeps_corruption() -> void:
    ls.apply_tension(50)
    ls.add_corruption(30)
    ls.reset_tension()
    assert_eq(ls.tension, 0.0)
    assert_eq(ls.corruption, 30.0)
