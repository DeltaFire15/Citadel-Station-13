//A rifle made of brass; It is a strong means of supression due to it being able to recharge via draining power from the ark itself. Damage increases as its user takes damage.
/obj/item/gun/energy/steamrifle // Not a clockwork/weaopon subtype due to me not wanting to have to rewrite guncode.
	name = "Steamrifle"
	desc = "A pointed gunlike object made out of brass.. It hums with activity and releases steam from time to time."
	var/clockwork_desc = "A effective rifle made out of brass. It recharges via draining power from the ark itself."
	resistance_flags = FIRE_PROOF | ACID_PROOF
	can_charge = 0
	charge_delay = 5
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "steamrifle"
	item_state = "steamrifle"
	ammo_type = list(/obj/item/ammo_casing/energy/brass_bolt)
	cell_type = /obj/item/stock_parts/cell{charge = 2000; maxcharge = 2000}
	var/mob/living/gunowner = null
	var/enrage_damage = 0 // Additional damage determinated by how much the weapons summoner is injured (note: Not neccessarily the holder if it got dropped for example, though cultsts can just resummon it to their position)
	var/enrage_maximum = 20 //The maximum damage enrage can add
	var/enrage_amount_per = 2 //How much damage increases per step
	var/enrage_step = 3 //Every how many percent damage increases
/obj/item/gun/energy/steamrifle/examine(mob/user)
	if((is_servant_of_ratvar(user) || isobserver(user)) && clockwork_desc)
		desc = clockwork_desc
	. = ..()
	desc = initial(desc)


/obj/item/gun/energy/steamrifle/process()
	. = ..()
	charge_tick++
	if(charge_tick > charge_delay)
		if(cell?.charge < cell.maxcharge && get_clockwork_power(min(cell.maxcharge - cell?.charge, 100)))
			var/power_recharging = min(cell.maxcharge - cell?.charge, 100)
			adjust_clockwork_power(power_recharging)
			cell.give(power_recharging)
			charge_tick = 0
			update_icon()
			//playsound(src, 'sound/weapons/brass_charge.ogg', 100, 1)
	if(!gunowner)
		return
	enrage_damage = CLAMP(round(gunowner.health / gunowner.maxHealth /*might need a different proc here*/ / enrage_step, 0) * enrage_amount_per, 0, enrage_maximum)
	clockwork_desc = "A effective rifle made out of brass. It recharges via draining power from the ark itself. /n Currently its damage is increased by [enrage_damage] due to the injuries of its bound user."

/obj/item/gun/energy/steamrifle/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(!is_servant_of_ratvar(user))
		to_chat(user, "The Rifle releases a gush of steam but doesn't fire...")
		to_chat(user, "<span class='heavy_brass'>\"It is not for you to decide who lives and who dies.\"</span>")
		//Possibly add a sound here too
		return FALSE
	if(chambered.BB)
		chambered.BB.damage += enrage_damage //Fix this to not be able to stack
	. = ..()

/obj/item/ammo_casing/energy/brass_bolt
	projectile_type = /obj/item/projectile/energy/brass_bolt
	e_cost = 100
	fire_sound = 'sound/weapons/laser.ogg' //Change this

/obj/item/projectile/energy/brass_bolt
	name = "brass bolt"
	icon_state = "spark" //Change this
	damage = 15
	is_reflectable = FALSE

