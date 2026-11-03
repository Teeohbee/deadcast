# scenes/barge_hub/MartaJobs.gd
# Marta's side jobs (ROADMAP 3.2): which job she offers, and whether a run
# met it. No scene-tree dependencies.
class_name MartaJobs

const JOB_PATHS: Array[String] = [
	"res://resources/jobs/quiet_water.tres",
	"res://resources/jobs/steady_hands.tres",
	"res://resources/jobs/exchange_ledger.tres",
	"res://resources/jobs/static_walk.tres",
	"res://resources/jobs/sub_basement.tres",
	"res://resources/jobs/dead_air.tres",
]

static func all_jobs() -> Array[JobData]:
	var jobs: Array[JobData] = []
	for path in JOB_PATHS:
		jobs.append(load(path))
	return jobs

static func find(job_id: String) -> JobData:
	for job in all_jobs():
		if job.id == job_id:
			return job
	return null

# One job per run, rotating through those unlocked so far. Null before the
# first dive, so the first dive stays a plain one.
static func offer_for(run_count: int) -> JobData:
	var unlocked: Array[JobData] = []
	for job in all_jobs():
		if job.min_run <= run_count:
			unlocked.append(job)
	if unlocked.is_empty():
		return null
	return unlocked[run_count % unlocked.size()]

static func is_met(job: JobData, facts: RunFacts) -> bool:
	if facts.snapped:
		return false
	match job.condition:
		JobData.Condition.NO_CUT_LINE:
			return not facts.cut_line
		JobData.Condition.NO_ENTITY_ENGAGED:
			return not facts.entity_engaged
		JobData.Condition.LAND_TYPE_IN_ZONE:
			return facts.zone_id == job.zone_id and facts.landed_types.has(job.catch_type)
		JobData.Condition.HIGH_CORRUPTION_STREAK:
			return longest_streak(facts.corruption_per_contact, job.corruption_threshold) >= job.streak_length
	return false

static func longest_streak(values: Array, threshold: float) -> int:
	var longest := 0
	var current := 0
	for value in values:
		if value >= threshold:
			current += 1
			longest = max(longest, current)
		else:
			current = 0
	return longest
