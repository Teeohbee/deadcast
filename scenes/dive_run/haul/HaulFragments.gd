# scenes/dive_run/haul/HaulFragments.gd
# The hex block that hangs under a haul payload, with fragments of the file hidden in
# it word-search style. Ported from the prototype (planning/deadcast/2026-11-05-haul-poc.html).
#
# - Each fragment sits across or down, in story order from the top (fragment i starts in
#   the i-th horizontal band). Letters sit on the character grid, not on hex pairs, so a
#   word straddles pairs - that's what hides it.
# - Rows light up once they've risen past the decode line, and stay lit.
# - A fragment is read when all its rows are lit. A hit taken while hauling scrambles the
#   latest fragment with any lit cell - read or half-read - and it never comes back.
#
# Fragments are hints about the haul, not always sentences. Rows and the decode line are
# screen geometry, so the view decides how many rows have risen and passes that in.
class_name HaulFragments
extends RefCounted

const PAIRS := 14
const COLS := PAIRS * 2
const HEX := "0123456789ABCDEF"

const READ := "read"
const LOST := "lost"
const UNREAD := "unread"

var rows: int
var filler: Array = []  # [row][col] hex digit, rewritten now and then by the view for shimmer
var letters: Array = [] # [row][col] fragment letter or ""
## In story order. Each: { word, cells: Array[Vector2i] (row, col), lost: bool, read_t: float (-1 unread) }
var fragments: Array[Dictionary] = []
var lit: Array[bool] = []
var lit_t: PackedFloat32Array
var _cell_owner := {} # Vector2i -> fragment index
var _rng: HaulSim.Lcg

## Letters only: fragments can carry spaces and punctuation that the block doesn't show.
static func clean(word: String) -> String:
	var out := ""
	for ch in word:
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == ".":
			out += ch
	return out

## Picks what one haul carries from a contact's pool: 3 or 4 fragments (all of a smaller
## pool), always including `always`, kept in pool order so sequences still read top down.
static func draw(pool: PackedStringArray, always: PackedStringArray, rng: HaulSim.Lcg = null) -> PackedStringArray:
	var rand := func() -> float: return rng.next() if rng else randf()
	var want := mini(pool.size(), 3 + (1 if rand.call() < 0.5 else 0))
	var picked := {}
	for w in always:
		var i := pool.find(w)
		if i >= 0:
			picked[i] = true
	var rest: Array[int] = []
	for i in pool.size():
		if not picked.has(i):
			rest.append(i)
	while picked.size() < want and not rest.is_empty():
		picked[rest.pop_at(int(rand.call() * rest.size()))] = true
	var order: Array = picked.keys()
	order.sort()
	var out := PackedStringArray()
	for i in order:
		out.append(pool[i])
	return out

func _init(words: PackedStringArray, p_rows: int, rng: HaulSim.Lcg = null) -> void:
	rows = p_rows
	_rng = rng
	for r in rows:
		var f: Array[String] = []
		var l: Array[String] = []
		for c in COLS:
			f.append(HEX[int(_rand() * 16.0)])
			l.append("")
		filler.append(f)
		letters.append(l)
	lit.resize(rows)
	lit.fill(false)
	lit_t.resize(rows)
	for i in words.size():
		_place(words[i], i, words.size())

func _rand() -> float:
	return _rng.next() if _rng else randf()

func _place(word: String, i: int, count: int) -> void:
	var w := clean(word)
	if w.is_empty():
		return
	var band0 := floori(float(i * rows) / count)
	var band1 := maxi(band0 + 1, floori(float((i + 1) * rows) / count))
	var cells: Array[Vector2i] = []
	for tries in 300:
		var down := ((_rand() < 0.5) if (i % 2 == 1 or tries > 150) else false) and w.length() <= rows - band0
		var row_span := (mini(band1, rows - w.length() + 1) if down else band1) - band0
		var r0 := band0 + int(_rand() * maxi(1, row_span))
		var c0 := int(_rand() * (COLS if down else COLS - w.length() + 1))
		var cand: Array[Vector2i] = []
		for k in w.length():
			var cell := Vector2i(r0 + k, c0) if down else Vector2i(r0, c0 + k)
			if cell.x >= rows or cell.y < 0 or cell.y >= COLS or (letters[cell.x][cell.y] != "" and letters[cell.x][cell.y] != w[k]):
				break
			cand.append(cell)
		if cand.size() == w.length():
			cells = cand
			break
	if cells.is_empty():
		push_warning("HaulFragments: no room for '%s'" % word)
		return
	for k in cells.size():
		letters[cells[k].x][cells[k].y] = w[k]
		_cell_owner[cells[k]] = fragments.size()
	fragments.append({ "word": word, "cells": cells, "lost": false, "read_t": -1.0 })

## Index of the fragment whose letter sits in this cell, or -1.
func owner_at(row: int, col: int) -> int:
	return _cell_owner.get(Vector2i(row, col), -1)

func is_read(f: Dictionary) -> bool:
	return f.read_t >= 0.0 and not f.lost

func read_count() -> int:
	return fragments.filter(is_read).size()

func _touched(f: Dictionary) -> bool:
	return f.cells.any(func(c: Vector2i) -> bool: return lit[c.x])

## Lights rows [0, rows_risen) and applies a hit. Returns indices of fragments read this update.
func update(dt: float, rows_risen: int, hit: bool) -> Array[int]:
	for r in rows:
		if not lit[r] and r < rows_risen:
			lit[r] = true
			lit_t[r] = 0.0
		elif lit[r]:
			lit_t[r] += dt
	if hit:
		for i in range(fragments.size() - 1, -1, -1):
			if not fragments[i].lost and _touched(fragments[i]):
				fragments[i].lost = true
				break
	var newly: Array[int] = []
	for i in fragments.size():
		var f := fragments[i]
		if f.read_t >= 0.0:
			f.read_t += dt
		elif not f.lost and f.cells.all(func(c: Vector2i) -> bool: return lit[c.x]):
			f.read_t = 0.0
			newly.append(i)
	return newly

## What the haul brought up, in story order: [{ word, state: READ | LOST | UNREAD }].
func recovered(snapped: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in fragments:
		var state := UNREAD
		if snapped or f.lost:
			state = LOST
		elif f.read_t >= 0.0:
			state = READ
		out.append({ "word": f.word, "state": state })
	return out
