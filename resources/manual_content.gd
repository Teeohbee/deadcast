# resources/manual_content.gd
class_name ManualContent

const SECTIONS: Array[Dictionary] = [
	{
		"title": "DIVE OPERATIONS",
		"body": "the meridian's trawl line deploys into the sump.\ncatches arrive in slots. each presents options with\ndifferent tension and credit trade-offs.\n\ntension accumulates across the run.\nline snap = run forfeited. all credits lost.",
	},
	{
		"title": "CATCH CLASSIFICATION",
		"body": "four types:\n  DATA    archived records, encrypted files\n  BIO     organic specimens, tissue samples\n  MECH    machines, drones, automated systems\n  ENTITY  residual presences, signal ghosts\n\nfour behaviours:\n  PASSIVE      standard extraction, no countermeasures\n  RESISTANT    may push back on extraction attempts\n  NEGOTIATING  responsive to structured queries, outcomes vary\n  HOSTILE      active threat, requires terminal overload protocol",
	},
	{
		"title": "EQUIPMENT",
		"body": "rods have a tension cap and depth rating.\ndamaged rods reduce tension cap until repaired.\ndepth upgrades extend reach to deeper layers.\n\nlures modify encounters. check stock before diving.\n\nworkshop [F2] handles repairs and upgrades.",
	},
	{
		"title": "THE DECK",
		"body": "zone selection determines dive location.\neach zone has different conditions and catches.\n\nfreezer stores bio-catch credits between runs.\ncontents degrade over time. sell before they spoil.\n\naccount status shows wallet, debt, and payment schedule.",
	},
	{
		"title": "DECRYPT BOX",
		"body": "load credits into the decrypt queue.\nafter a set number of runs, decryption completes.\n\nresults vary.",
	},
	{
		"title": "DEBT",
		"body": "10,000cr payment due every 5 runs.\ndeducted automatically from wallet.\n\nmiss a payment and pressure increases.",
	},
]

static func format_full_manual() -> String:
	var sep := "────────────────────────────────────────────────────────────────"
	var lines: Array[String] = [
		"DEADCAST_OS :: OPERATOR MANUAL",
		sep,
		"",
	]
	for i in SECTIONS.size():
		var section: Dictionary = SECTIONS[i]
		lines.append("  %s" % section.title)
		lines.append("")
		for line in section.body.split("\n"):
			lines.append("  %s" % line)
		lines.append("")
		if i < SECTIONS.size() - 1:
			lines.append(sep)
			lines.append("")
	return "\n".join(lines)
