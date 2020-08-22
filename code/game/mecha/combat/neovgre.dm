/obj/mecha/combat/neovgre
	name = "Neovgre, the Anima Bulwark"
	desc = "Nezbere's most powerful creation, a mighty war machine of unmatched power said to have ended wars in a single night."
	icon = 'icons/mecha/neovgre.dmi'
	icon_state = "neovgre"
	max_integrity = 500 //This is THE ratvarian superweaon, its deployment is an investment
	armor = list("melee" = 50, "bullet" = 40, "laser" = 25, "energy" = 25, "bomb" = 50, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100) //Its similar to the clockwork armour albeit with a few buffs becuase RATVARIAN SUPERWEAPON!!
	force = 50 //SMASHY SMASHY!!
	internal_damage_threshold = 0
	step_in = 3
	pixel_x = -16
	layer = ABOVE_MOB_LAYER
	breach_time = 100 //ten seconds till all goes to shit
	recharge_rate = 100
	internals_req_access = list()
	add_req_access = 0
	wreckage = /obj/structure/mecha_wreckage/durand/neovgre
	stepsound = 'sound/mecha/neostep2.ogg'
	turnsound = 'sound/mecha/powerloader_step.ogg'

/obj/mecha/combat/neovgre/GrantActions(mob/living/user, human_occupant = 0) //No Eject action for you sonny jim, your life for Ratvar!
	internals_action.Grant(user, src)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)

/obj/mecha/combat/neovgre/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)

/obj/mecha/combat/neovgre/MouseDrop_T(mob/M, mob/user)
	if(!is_servant_of_ratvar(user))
		to_chat(user, "<span class='neovgre'>BEGONE HEATHEN!</span>")
		return
	else
		..()

/obj/mecha/combat/neovgre/moved_inside(mob/living/carbon/human/H)
	var/list/Itemlist = H.get_contents()
	for(var/obj/item/clockwork/slab/W in Itemlist)
		to_chat(H, "<span class='brass'>You safely store [W] inside [src].</span>")
		qdel(W)
	. = ..()

/obj/mecha/combat/neovgre/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, "<span class='brass'>You are consumed by the fires raging within Neovgre...</span>")
		M.dust()
	playsound(src, 'sound/effects/neovgre_exploding.ogg', 100, 0)
	src.visible_message("<span class = 'userdanger'>The reactor has gone critical, its going to blow!</span>")
	addtimer(CALLBACK(src,.proc/go_critical),breach_time)

/obj/mecha/combat/neovgre/proc/go_critical()
	explosion(get_turf(loc), 3, 5, 10, 20, 30)
	Destroy(src)

/obj/mecha/combat/neovgre/container_resist(mob/living/user)
	to_chat(user, "<span class='brass'>Neovgre requires a lifetime commitment friend, no backing out now!</span>")
	return

/obj/mecha/combat/neovgre/process()
	..()
	if(GLOB.ratvar_awakens) // At this point only timley intervention by lord singulo could hope to stop the superweapon
		cell.charge = INFINITY
		max_integrity = INFINITY
		obj_integrity = max_integrity
		CHECK_TICK //Just to be on the safe side lag wise
	else
		if(cell.charge < cell.maxcharge)
			for(var/obj/effect/clockwork/sigil/transmission/T in range(SIGIL_ACCESS_RANGE, src))
				var/delta = min(recharge_rate, cell.maxcharge - cell.charge)
				if (get_clockwork_power() >= delta)
					cell.charge += delta
					adjust_clockwork_power(-delta)
		if(obj_integrity < max_integrity && istype(loc, /turf/open/floor/clockwork))
			obj_integrity += min(max_integrity - obj_integrity, max_integrity / 200)
		CHECK_TICK

/obj/mecha/combat/neovgre/Initialize()
	.=..()
	GLOB.neovgre_exists ++
	var/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy/neovgre/N = new
	N.attach(src)
	var/obj/item/mecha_parts/mecha_equipment/weapon/energy/boltdriver/B = new
	B.attach(src)

/obj/structure/mecha_wreckage/durand/neovgre
	name = "\improper Neovgre wreckage?"
	desc = "On closer inspection this looks like the wreck of a durand with some spraypainted cardboard duct taped to it!"

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy/neovgre
	equip_cooldown = 8 //Rapid fire heavy laser cannon, simple yet elegant
	energy_drain = 30
	name = "Arbiter Laser Cannon"
	desc = "Please re-attach this to neovgre and stop asking questions about why it looks like a normal Nanotrasen issue Solaris laser cannon - Nezbere"
	fire_sound = 'sound/weapons/neovgre_laser.ogg'

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy/neovgre/can_attach(obj/mecha/combat/neovgre/M)
	if(istype(M))
		return 1
	return 0

//Boltdriver. Heavy weapon firing brass bolts at extreme velocities after a short chargeup telegraphing its shot. If you see its targetting beam indicating a chargeup, move out of it immediately
//Overrides the normal weapon action due to its special telegraphed chargeup.
/obj/item/mecha_parts/mecha_equipment/weapon/energy/boltdriver
	name = "\improper Boltdriver"
	desc = "An abomination of a weapon firing a high-velocity bolt piercing through targets. Requires a moment of chargeup for the rail supercapacitors before firing."
	harmful = TRUE //Yeah you bet this is harmful
	equip_cooldown = 50 //Supercapacitors need quite a while to recharge
	energy_drain = 300
	projectile = /obj/item/projectile/bullet/brass_bolt
	var/chargeup_time = 10
	var/list/obj/effect/projectile/tracer/current_tracers

/obj/item/mecha_parts/mecha_equipment/weapon/energy/boltdriver/can_attach(obj/mecha/combat/neovgre/M)
	if(istype(M))
		return 1
	return 0

/obj/item/mecha_parts/mecha_equipment/weapon/energy/boltdriver/action(atom/target, params)
	if(!action_checks(target))
		return 0

	var/turf/curloc = get_turf(chassis)
	var/turf/targloc = get_turf(target)
	if (!targloc || !istype(targloc) || !curloc)
		return 0
	if (targloc == curloc)
		return 0

	set_ready_state(0)
	var/obj/item/projectile/beam/beam_rifle/hitscan/aiming_beam/boltdriver_chargeup_beam/BC = new
	BC.gun = src
	BC.wall_pierce_amount = 2
	BC.structure_pierce_amount = 8
	BC.do_pierce = TRUE
	BC.color = rgb(255, 163, 26)
	BC.preparePixelProjectile(targloc, chassis.occupant)
	BC.fire()
	if(!do_after_mecha(targloc, chargeup_time))
		set_ready_state(1)
		QDEL_LIST(current_tracers)
		return
	STOP_PROCESSING(SSfastprocess, src)
	QDEL_LIST(current_tracers)
	target = targloc
	for(var/mob/M in targloc)
		target = M
		break
	set_ready_state(1)
	return ..()

/obj/item/projectile/bullet/brass_bolt
	icon_state = "magjectile" //TODO
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE
	embedding = list(embed_chance=0, fall_chance=2, jostle_chance=0, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.5, pain_mult=3, rip_time=10) //Yeah no these can't embed. They just tear through people instead.
	damage_type = BRUTE
	flag = "energy"
	damage = 65
	armour_penetration = 25
	light_range = 3
	pixels_per_second = TILES_TO_PIXELS(16.667*3) //Written this way to make clear it is thrice as fast as a normal bullet
	range = 60
	light_color = LIGHT_COLOR_ORANGE
	var/mob_obj_penetration = 8
	var/wallpenetration = 2
	var/turf/cached
	var/list/pierced = list()

/obj/item/projectile/bullet/brass_bolt/proc/check_pierce(atom/target)
	if(pierced[target])		//we already pierced them go away
		return TRUE
	if(isclosedturf(target))
		if(wallpenetration > 0)
			wallpenetration--
			return TRUE
	if(ismovable(target))
		var/atom/movable/AM = target
		if(AM.density && !AM.CanPass(src, get_turf(target)) && !ismob(AM))
			if(mob_obj_penetration > 0)
				if(isobj(AM))
					var/obj/O = AM
					O.take_damage(damage, BRUTE, "energy", FALSE) //Fast enough to be considered an energy projectile when overpenetrating, though it still causes brute damage
				pierced[AM] = TRUE
				mob_obj_penetration--
				return TRUE
	return FALSE

/*
/obj/item/projectile/bullet/brass_bolt/proc/handle_impact(atom/target)
	if(isobj(target))
		var/obj/O = target
		O.take_damage(damage, BRUTE, "energy", FALSE)
	if(isliving(target))
		var/mob/living/L = target
		L.adjustBruteLoss(damage)
		L.emote("scream")

/obj/item/projectile/bullet/brass_bolt/proc/handle_hit(atom/target)
	set waitfor = FALSE
	if(!cached && !QDELETED(target))
		cached = get_turf(target)
	if(!QDELETED(target))
		handle_impact(target)
*/

/obj/item/projectile/bullet/brass_bolt/Bump(atom/target)
	if(check_pierce(target))
		permutated += target
		trajectory_ignore_forcemove = TRUE
		forceMove(target.loc)
		trajectory_ignore_forcemove = FALSE
		return FALSE
	if(!QDELETED(target))
		cached = get_turf(target)
	. = ..()

/obj/item/projectile/bullet/brass_bolt/on_hit(atom/target, blocked = FALSE)
	if(!QDELETED(target))
		cached = get_turf(target)
	//handle_hit(target)
	if(mob_obj_penetration > 0 && !isturf(target))
		. = BULLET_ACT_FORCE_PIERCE
		mob_obj_penetration--
	return ..()

/obj/item/projectile/beam/beam_rifle/hitscan/aiming_beam/boltdriver_chargeup_beam
	name = "targetting beam"
	hitscan_light_color_override = "#ffa31a"
