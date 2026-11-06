// Used to hold any procs related to how mindflayers are handled from a gamemode perspective.
/datum/game_mode/proc/auto_declare_completion_mindflayer()
	if(!length(mindflayers))
		return

	var/list/text = list(span_bold(span_fontsize2("The mindflayers were:")))
	for(var/datum/mind/mindflayer in mindflayers)
		var/traitorwin = TRUE
		text += "<br>[mindflayer.get_mind_key()] was [mindflayer.name] and "
		if(mindflayer.current)
			if(mindflayer.current.stat == DEAD)
				text += span_bold("died!")
			else
				text += span_bold("survived!")
		else
			text += span_bold("had their body destroyed!")

		var/list/all_objectives = mindflayer.get_all_objectives()

		if(length(all_objectives))
			var/count = 1
			for(var/datum/objective/objective in all_objectives)
				text += "<br><b>Objective #[count]</b>: [objective.explanation_text]"
				if(objective.check_completion())
					if(istype(objective, /datum/objective/steal))
						var/datum/objective/steal/steal_objective = objective
						SSblackbox.record_feedback("nested tally", "mindflayer_steal_objective", 1, list("Steal [steal_objective.steal_target]", "SUCCESS"))
					else
						SSblackbox.record_feedback("nested tally", "mindflayer_objective", 1, list("[objective.type]", "SUCCESS"))
				else
					if(istype(objective, /datum/objective/steal))
						var/datum/objective/steal/steal_objective = objective
						SSblackbox.record_feedback("nested tally", "mindflayer_steal_objective", 1, list("Steal [steal_objective.steal_target]", "FAIL"))
					else
						SSblackbox.record_feedback("nested tally", "mindflayer_objective", 1, list("[objective.type]", "FAIL"))
					traitorwin = FALSE
				count++

		if(traitorwin)
			SSblackbox.record_feedback("tally", "mindflayer_success", 1, "SUCCESS")
		else
			SSblackbox.record_feedback("tally", "mindflayer_success", 1, "FAIL")

	return text.Join("")