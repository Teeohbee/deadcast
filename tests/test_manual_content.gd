# tests/test_manual_content.gd
extends GutTest

func test_sections_is_not_empty() -> void:
	var sections := ManualContent.SECTIONS
	assert_gt(sections.size(), 0)

func test_each_section_has_title_and_body() -> void:
	for section in ManualContent.SECTIONS:
		assert_has(section, "title", "Section missing 'title' key")
		assert_has(section, "body", "Section missing 'body' key")
		assert_typeof(section.title, TYPE_STRING)
		assert_typeof(section.body, TYPE_STRING)
		assert_gt(section.title.length(), 0, "Section title is empty")
		assert_gt(section.body.length(), 0, "Section body is empty")

func test_section_count_matches_spec() -> void:
	assert_eq(ManualContent.SECTIONS.size(), 6)
