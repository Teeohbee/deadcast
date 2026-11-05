# scenes/relay/RelayActions.gd
# Applies the game effects a relay script asks for with a "do" step
# (RelayScripts.ACTIONS). Kept apart from RelayRunner so the runner stays pure.
class_name RelayActions

static func apply(action: String) -> void:
	match action:
		RelayScripts.ACTION_ACCEPT_JOB:
			var offer := MartaJobs.offer_for(GameState.run_count)
			if offer != null and GameState.job_offer_open():
				GameState.accept_job(offer.id)
		RelayScripts.ACTION_DECLINE_JOB:
			GameState.decline_job()
		_:
			push_error("RelayActions: unknown action %s" % action)
