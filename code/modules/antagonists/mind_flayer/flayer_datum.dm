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
