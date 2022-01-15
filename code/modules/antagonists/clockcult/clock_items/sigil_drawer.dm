
GLOBAL_LIST_INIT(sigil_component_types, typesof(/obj/effect/clockwork/custom_sigil))
#define LINKING_MODE 0
#define DESIGNATION_MODE 1

/obj/item/clockwork/sigil_drawer
    name = "sigil component fabricator"
    desc = "An odd, L-shaped device that hums with energy." //Yes this is a repurposed replica fabricator, you got me. I guess I can do a little coderspriting on top of it.
    clockwork_desc = "A device that allows the drawing of custom sigils, which allow casting some spells alone or with enhanced effects."
    icon_state = "replica_fabricator"
    lefthand_file = 'icons/mob/inhands/antag/clockwork_lefthand.dmi'
    righthand_file = 'icons/mob/inhands/antag/clockwork_righthand.dmi'
    w_class = WEIGHT_CLASS_NORMAL
    force = 5
    item_flags = NOBLUDGEON
    var/obj/effect/clockwork/custom_sigil/buffered
    var/selected = 1
    var/mode = 0    //to toggle inbetween drawing / linking and designation mode.
    var/startx = 0
    var/endx = 0
    var/starty = 0
    var/endy = 0

/obj/item/clockwork/sigil_drawer/Destroy()
    if(buffered)
        buffered.saved_by = null
        buffered = null
    return ..()

/obj/item/clockwork/sigil_drawer/attack_self(mob/user)
    . = ..()
    if(mode == LINKING_MODE)
        selected = (selected % length(GLOB.sigil_component_types)) + 1 //TEMP selection method - will likely be radials.
        var/obj/effect/clockwork/custom_sigil/selected_sigil_path = GLOB.sigil_component_types[selected]
        to_chat(user, "<span class='notice'>You select the [initial(selected_sigil_path.sigil_component_name)] sigil component.</span>")
    else
        startx = 0
        endx = 0
        starty = 0
        endy = 0
        to_chat(user, "<span class='notice'>You reset the designation area.</span>")

/obj/item/clockwork/sigil_drawer/pre_attack(atom/A, mob/living/user, params, attackchain_flags, damage_multiplier)
    if(!user.Adjacent(A) || !is_servant_of_ratvar(user) || (!isopenturf(A) && !istype(A, /obj/effect/clockwork/custom_sigil)))
        return ..()
    if(isopenturf(A))
        if(mode == LINKING_MODE)
            try_drawing_component(A, user)
        else if(!startx)
            startx = A.x
            starty = A.y
            to_chat(user, "<span class='notice'>Start point marked.</span>")
        else if(!endx)
            if(A.x == startx && A.y == starty)
                to_chat(user, "<span class='warning'>You really shouldn't create an area this small.</span>")
            else
                endx = A.x
                endy = A.y
                to_chat(user, "<span class='notice'>End point marked.</span>")
        else
            to_chat(user, "<span class='warning'>You already have an finished area selected. Use inhand if you wish to reset it.</span>")
        return
    var/obj/effect/clockwork/custom_sigil/target_sigil = A
    if(mode == LINKING_MODE)
        if(buffered)
            if(A != buffered)
                target_sigil.link_component(user, buffered)
            else
                target_sigil.saved_by = null
                buffered = null
                to_chat(user, "<span class='notice'>You delete [src]'s sigil buffer.</span>")
        else
            if(!target_sigil.saved_by)
                to_chat(user, "<span class='notice'>You save the [target_sigil.sigil_component_name] component to [src]'s buffer.</span>")
                target_sigil.saved_by = src
                buffered = target_sigil
            else
                to_chat(user, "<span class='warning'>The [target_sigil.sigil_component_name] component is already being linked.</span>")
    else
        if(!istype(target_sigil, /obj/effect/clockwork/custom_sigil/core))
            to_chat(user, "<span class='warning'>The saved area must be copied to a sigil core and not any other component.</span>")
            return
        if(!endx)
            to_chat(user, "<span class='warning'>You must have an area designated to be able to designate it on a core.</span>")
            return
        var/obj/effect/clockwork/custom_sigil/core/sigil_core = target_sigil
        sigil_core.core_sigil_link.setup_area(startx, starty, endx, endy)
        to_chat(user, "<span class='notice'>You designate the core's sigil area as the saved one.</span>")

/obj/item/clockwork/sigil_drawer/proc/try_drawing_component(turf/target_turf, mob/user)
    if(locate(/obj/effect/clockwork/custom_sigil) in target_turf)
        to_chat(user, "<span class='warning'>This place already has a sigil!</span>")
        return
    if(!do_after(user, 3 SECONDS, target = target_turf))
        return
    if(locate(/obj/effect/clockwork/custom_sigil) in target_turf)
        to_chat(user, "<span class='warning'>Looks like someone already created a sigil component here in the meantime!</span>")
    var/sigil_path = GLOB.sigil_component_types[selected]
    new sigil_path(target_turf)

/obj/item/clockwork/sigil_drawer/altafterattack(atom/target, mob/user, proximity_flag, click_parameters)
    . = TRUE
    if(!is_servant_of_ratvar(user))
        return
    mode = !mode
    to_chat(user, "<span class='notice'>You switch to [mode == LINKING_MODE ? "linking mode" : "designation mode"].</span>")

/obj/item/clockwork/sigil_drawer/examine(mob/user)
    . = ..()
    if(!is_servant_of_ratvar(user))
        return
    . += "<span class='brass'>You can right-click in combat mode to toggle this between drawing / linking mode and area designation mode.</span>"
    . += "<span class='brass'>Using it inhand in linking mode will cycle between sigil components, while doing it in designation mode will clear the saved zone.</span>"

#undef LINKING_MODE
#undef DESIGNATION_MODE
