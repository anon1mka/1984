/datum/antagonist/mindflayer
	name = "Mindflayer"
	roundend_category = "mindflayers"
	job_rank = ROLE_MIND_FLAYER
	special_role = SPECIAL_ROLE_MIND_FLAYER
	antag_hud_type = ANTAG_HUD_MIND_FLAYER
	antag_hud_name = "hudflayer"
	wiki_page_name = "Mindflayer"
	russian_wiki_name = "Пожиратель разума"
	antag_menu_name = "Пожиратель разума"
	give_objectives = FALSE

	/// The current amount of swarms the mind flayer has access to purchase with.
	var/usable_swarms = 0
	/// The total points of brain damage the flayer has harvested, only used for logging purposes.
	var/total_swarms_gathered = 0
	/// The current person being drained.
	var/mob/living/carbon/human/harvesting
	/// The list of all purchased spell and passive objects.
	var/list/powers = list()
	/// A list of all powers and passives mindflayers can buy.
	var/list/ability_list = list()
	/// List for keeping track of who has already been drained.
	var/list/drained_humans = list()
	/// How fast the flayer's touch drains.
	var/drain_multiplier = 1
	/// The base brain damage dealt per tick of the drain.
	var/drain_amount = 0.5
	/// A list of the categories and their associated stages of the power.
	var/list/category_stage = list(FLAYER_CATEGORY_GENERAL = 1, FLAYER_CATEGORY_DESTROYER = 1, FLAYER_CATEGORY_INTRUDER = 1)
	/// If the mindflayer can still pick a stage 4 ability.
	var/can_pick_capstone = TRUE
	/// Have we notified that our victim does not give swarms from draining.
	var/has_notified = FALSE

/datum/antagonist/mindflayer/add_owner_to_gamemode()
	SSticker.mode.mindflayers += owner

/datum/antagonist/mindflayer/remove_owner_from_gamemode()
	SSticker.mode.mindflayers -= owner

/datum/antagonist/mindflayer/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/user = .
	if(user)
		user.faction |= "flayer"

/datum/antagonist/mindflayer/remove_innate_effects(mob/living/mob_override)
	var/mob/living/user = mob_override || owner.current
	. = ..()
	if(user)
		user.faction -= "flayer"

/datum/antagonist/mindflayer/greet()
	. = list()
	if(owner?.current && !silent)
		. += span_userdanger("Вы — пожиратель разума!")
		. += "Высасывайте мозги голой рукой на вредоносном намерении, чтобы получать рои, затем тратьте их в меню самолучшения."

/datum/antagonist/mindflayer/Destroy(force)
	harvesting = null
	LAZYCLEARLIST(drained_humans)
	var/mob/living/user = owner?.current
	if(user && !QDELETED(user))
		var/datum/hud/hud = user.hud_used
		if(hud && !QDELETED(hud))
			hud.remove_mindflayer_hud()
	. = ..()

/datum/antagonist/mindflayer/vv_edit_var(var_name, var_value)
	. = ..()
	if(var_name == "usable_swarms")
		update_swarm_hud()

/datum/antagonist/mindflayer/proc/get_swarms()
	return usable_swarms

/datum/antagonist/mindflayer/proc/set_swarms(amount, update_total = FALSE)
	var/old_swarm_amount = usable_swarms
	usable_swarms = amount
	if(update_total)
		var/difference = usable_swarms - old_swarm_amount
		if(difference > 0)
			total_swarms_gathered += difference
	update_swarm_hud()

/datum/antagonist/mindflayer/proc/adjust_swarms(amount, bound_lower = 0, bound_upper = INFINITY)
	set_swarms(clamp(usable_swarms + amount, bound_lower, bound_upper), TRUE)

/datum/antagonist/mindflayer/proc/update_swarm_hud()
	handle_mindflayer()

/datum/antagonist/mindflayer/proc/send_swarm_message(message)
	var/mob/living/user = owner?.current
	if(!user || QDELETED(user))
		return
	if(HAS_TRAIT(user, TRAIT_MINDFLAYER_NULLIFIED))
		message = "zzt... [message]"
	to_chat(user, span_userdanger("[message]"))

/datum/antagonist/mindflayer/proc/check_valid_harvest(mob/living/carbon/human/H)
	if(!owner?.current || QDELETED(owner.current) || !H || QDELETED(H))
		return FALSE

	if(HAS_TRAIT(owner.current, TRAIT_MINDFLAYER_NULLIFIED))
		send_swarm_message("We do not have the energy for this...")
		return FALSE

	if(IS_MINDFLAYER(H))
		send_swarm_message("Their hive rejects the connection.")
		return FALSE

	var/obj/item/organ/internal/brain/brain = H.get_int_organ(/obj/item/organ/internal/brain)
	if(!istype(brain))
		send_swarm_message("This entity has no brain to harvest from.")
		return FALSE

	if(!H.ckey && !H.player_ghosted)
		send_swarm_message("This brain does not contain the spark that feeds us. Find more suitable prey.")
		return FALSE

	if(brain.get_effective_damage() >= brain.max_damage || (H.stat == DEAD && !H.has_status_effect(STATUS_EFFECT_RECENTLY_SUCCUMBED)))
		send_swarm_message("We detect no neural activity to harvest from this brain.")
		return FALSE

	var/unique_drain_id = H.UID()
	if(isnull(drained_humans[unique_drain_id]))
		drained_humans[unique_drain_id] = 0
	else if(drained_humans[unique_drain_id] > BRAIN_DRAIN_LIMIT)
		if(!has_notified)
			has_notified = TRUE
			send_swarm_message("You have drained most of the life force from [H]'s brain, and you will get no more swarms from them!")
		return DRAIN_BUT_NO_SWARMS

	return TRUE

/datum/antagonist/mindflayer/proc/handle_harvest(mob/living/carbon/human/H)
	var/mob/living/carbon/human/user = owner?.current
	if(!user || QDELETED(user) || !H || QDELETED(H) || harvesting)
		return

	harvesting = H

	var/obj/item/organ/internal/brain/drained_brain = H.get_int_organ(/obj/item/organ/internal/brain)
	if(!istype(drained_brain))
		harvesting = null
		return

	user.visible_message(
		span_danger("[user] puts [user.p_their()] fingers on [H]'s head and begins harvesting!"),
		span_userdanger("We begin our harvest on [H].")
	)
	to_chat(H, span_notice("You hear the hum of electricity."))

	if(!do_after(user, 2 SECONDS, H, show_progress = FALSE))
		if(!QDELETED(src))
			send_swarm_message("Our connection was incomplete.")
			harvesting = null
			has_notified = FALSE
		return

	var/unique_drain_id = H.UID()

	while(do_after(user, DRAIN_TIME, H, show_progress = FALSE))
		if(QDELETED(src) || QDELETED(user) || QDELETED(H) || QDELETED(drained_brain) || drained_brain.loc != H || owner?.current != user)
			break

		var/check_harvest = check_valid_harvest(H)
		if(!check_harvest)
			break

		H.Beam(user, icon_state = "b_beam", icon = 'icons/effects/beam.dmi', time = DRAIN_TIME, beam_color = COLOR_ASSEMBLY_PURPLE)

		var/datum/species/victim_species = H.dna?.species
		var/species_brain_mod = (victim_species && isnum(victim_species.brain_mod)) ? victim_species.brain_mod : 1
		var/physiology_brain_mod = (H.physiology && isnum(H.physiology.brain_mod)) ? H.physiology.brain_mod : 1
		var/damage_to_deal = drain_amount * drain_multiplier * species_brain_mod * physiology_brain_mod
		H.adjustBrainLoss(damage_to_deal, forced = TRUE)

		if(check_harvest != DRAIN_BUT_NO_SWARMS)
			adjust_swarms(damage_to_deal)
			drained_humans[unique_drain_id] += damage_to_deal

		drained_brain.max_damage = max(1, drained_brain.max_damage - 0.25)
		drained_brain.temporary_damage += 0.25

	if(!QDELETED(src))
		send_swarm_message("Our connection severs.")
		harvesting = null
		has_notified = FALSE

/datum/antagonist/mindflayer/proc/handle_mindflayer()
	var/mob/living/user = owner?.current
	if(!user || QDELETED(user))
		return

	var/datum/hud/hud = user.hud_used
	if(!hud || QDELETED(hud))
		return

	if(!hud.flayer_swarm_display)
		hud.flayer_swarm_display = new /atom/movable/screen()
		hud.flayer_swarm_display.name = "Usable Swarms"
		hud.flayer_swarm_display.icon_state = "blood_display"
		hud.flayer_swarm_display.screen_loc = "WEST:7,CENTER-1:15"
		hud.static_inventory += hud.flayer_swarm_display
		hud.show_hud(hud.hud_version)

	hud.flayer_swarm_display.maptext = "<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='[COLOR_BLUE_LIGHT]'>[round(usable_swarms)]</font></div>"

/datum/hud/proc/remove_mindflayer_hud()
	if(flayer_swarm_display)
		static_inventory -= flayer_swarm_display
		QDEL_NULL(flayer_swarm_display)
