//Sigildrawing: Draw sigils of different types with a positional arrangement fitting to a spell on the ground, link them, cast a spell with modified effects.
//Careful! Once linked, sigils cannot be unlinked, and the only way to remove them is to destroy the sigil's core which will delete the entire sigil. Alternatively, somehow destroying a sigil in a link will also erase the link.

/obj/effect/clockwork/custom_sigil
    name = "pulsing sigil"
    desc = "a strange set of markings on the ground"
    var/sigil_component_name = "Conduit"
    clockwork_desc = "A sigil used for sigildrawing. This type simply serves as a conduit for the invocation and has no special effects."

    ///Sigils with which this one is linked with.
    var/list/connections = list()

    ///The core of the connected network
    var/obj/effect/clockwork/custom_sigil/core/sigil_core

    ///Special behavior of this sigil, e.g. blocking the power net in this direction, providing power, amping the spell, reducing cost, etc.
    var/sigil_flags = NONE

    ///If a sigil_drawer has this sigil saved. Provents other drawers from accessing it in the meantime, and clears its reference on del.
    var/obj/item/clockwork/sigil_drawer/saved_by

///Recursively passes down the sigil network, modifying the sigil links total stats. No loop checks due to preventing loops during linking. If I catch an admin varediting a loop in I'll plushify them.
/obj/effect/clockwork/custom_sigil/proc/sigil_link_effect(datum/sigil_link/invocation_link, obj/effect/clockwork/custom_sigil/incoming_from, list/passed_nodes)
    var/current_power = 0
    for(var/obj/effect/clockwork/custom_sigil/applying as anything in passed_nodes)
        if((sigil_flags & SIGIL_NEEDS_POWER) && (applying.sigil_flags & SIGIL_POWERING))
            current_power++
        if((sigil_flags & SIGIL_NEEDS_POWER) && (applying.sigil_flags & SIGIL_DRAINING))
            current_power--
        
    if(!(sigil_flags & SIGIL_NEEDS_POWER))   
        current_power = 1
    
    if(current_power)
        if(sigil_flags & SIGIL_STRENGTHENING)
            invocation_link.strength_mod += current_power
        if(sigil_flags & SIGIL_WEAKENING)
            invocation_link.strength_mod -= current_power
        if(sigil_flags & SIGIL_DISCOUNTING)
            invocation_link.cost_mod += current_power
        if(sigil_flags & SIGIL_COSTLY)
            invocation_link.cost_mod -= current_power
        if(sigil_flags & SIGIL_STABLE)
            invocation_link.backfire_mod += current_power
        if(sigil_flags & SIGIL_UNSTABLE)
            invocation_link.backfire_mod -= current_power
    for(var/obj/effect/clockwork/custom_sigil/applying as anything in passed_nodes)
        if((sigil_flags & SIGIL_GROUNDING) && ((applying.sigil_flags & SIGIL_POWERING) || (applying.sigil_flags & SIGIL_DRAINING)))
            passed_nodes.Remove(applying)
            continue
    for(var/obj/effect/clockwork/custom_sigil/continuing_to as anything in (connections - incoming_from))
        continuing_to.sigil_link_effect(invocation_link, src, (passed_nodes + src))

/obj/effect/clockwork/custom_sigil/Destroy()
    if(saved_by)
        saved_by.buffered = null
        saved_by = null
    if(sigil_core)
        sigil_core.core_sigil_link.link_failure(src)
    return ..()

/obj/effect/clockwork/custom_sigil/proc/link_component(mob/user, obj/effect/clockwork/custom_sigil/connect_to)
    if(sigil_core)
        to_chat(user, "<span class='warning'>This sigil is already linked to a core! The only way to break a the link is to destroy it.</span>")
        return FALSE
    if(!Adjacent(connect_to))
        to_chat(user, "<span class='warning'>The sigil you are trying to link this to is too far away!</span>")
        return FALSE
    if(!connect_to.sigil_core)
        to_chat(user, "span class='warning'>You have to link sigils outwards from a core or a sigil already linked to a core!</span>")
        return FALSE
    var/obj/effect/clockwork/custom_sigil/core/core_sigil = connect_to.sigil_core
    core_sigil.core_sigil_link.linked_sigils += src
    connections += connect_to
    connect_to.connections += src
    sigil_core = core_sigil
    update_icon()
    connect_to.update_icon()
    to_chat(user, "<span class='notice'>You successfully link the [connect_to.sigil_component_name] component to the [sigil_component_name] node.</span>")
    return TRUE
    
/obj/effect/clockwork/custom_sigil/core
    sigil_component_name = "Core"
    clockwork_desc = "A sigil component used for sigildrawing. This one is a core, which can be linked outwards from to form a functional sigil."
    var/datum/sigil_link/core_sigil_link

/obj/effect/clockwork/custom_sigil/core/New(loc, ...)
    . = ..()
    sigil_core = src
    core_sigil_link = new /datum/sigil_link(src)

/obj/effect/clockwork/custom_sigil/core/link_component(mob/user, obj/effect/clockwork/custom_sigil/connect_to)
    to_chat(user, "<span class='warning'>You cannot have two cores in one sigil!</span>")
    return FALSE


///A link of multiple sigils. Goes through all sigils connected and calculates effects.
/datum/sigil_link
    //Modifiers, for later applying, modified by the passed sigils. Higher is better, Lower is worse (negative = penalty)
    var/strength_mod = 0
    var/cost_mod = 0
    var/backfire_mod = 0

    var/list/linked_sigils = list()
    var/obj/effect/clockwork/custom_sigil/core/sigil_core

    //Area designation vars which specify which kind of sigil this is (e.g. how big it is / where its components can be)
    var/lowx
    var/highx
    var/lowy
    var/highy

/datum/sigil_link/New(link_core)
    . = ..()
    if(!link_core)
        return INITIALIZE_HINT_QDEL
    sigil_core = link_core
    linked_sigils += link_core

/datum/sigil_link/Destroy(force, ...)
    if(!sigil_core)
        return ..()
    for(var/obj/effect/clockwork/custom_sigil/sigil as anything in linked_sigils)
        sigil.sigil_core = null
        qdel(sigil)
    QDEL_NULL(linked_sigils)
    sigil_core = null
    return ..()
    
/datum/sigil_link/proc/link_failure(obj/effect/clockwork/custom_sigil/destroyed_sigil)
    linked_sigils -= destroyed_sigil
    destroyed_sigil.sigil_core = null
    qdel(src)

/datum/sigil_link/proc/calculate_sigil_effects()
    strength_mod = 0
    cost_mod = 0
    backfire_mod = 0
    sigil_core.sigil_link_effect(src, null, list())
    
/datum/sigil_link/proc/setup_area(_startx, _starty, _endx, _endy)
    if(_startx < _endx)
        lowx = _startx
        highx = _endx
    else
        lowx = _endx
        highx = _startx

    if(_starty < _endy)
        lowy = _starty
        highy = _endy
    else
        lowy = _endy
        highy = _starty

/datum/sigil_link/proc/check_validity()
    var/sizekey = "[highx-lowx+1]-[highy-lowy+1]"
    var/passedsigils = 0
    if(!GLOB.sigil_spell_areas[sizekey])
        message_admins("Invalid sizekey (xsize-ysize) [sizekey]")
        return FALSE    //Area size has no valid spells, abort.
    var/list/size_list = GLOB.sigil_spell_areas[sizekey]
    var/positionkey = ""
    for(var/checky = lowy; checky <= highy; checky++)
        for(var/checkx = lowx; checkx <= highx; checkx++)
            var/turf/checkturf = locate(checkx, checky, sigil_core.z)
            var/obj/effect/clockwork/custom_sigil/checking_for = locate() in checkturf
            if(!istype(checking_for))
                positionkey += "0"
            else
                if(checking_for.sigil_core != sigil_core)   //Invalid, no correct linkage
                    message_admins("Incorrect linkage")
                    return FALSE
                passedsigils++
                positionkey += "1"

    message_admins(positionkey)
    if(passedsigils != length(linked_sigils))   //Some there's too many sigils in the link, some outside of the area.
        message_admins("Sigil count discrepancy - aborting. [passedsigils] - [length(linked_sigils)]")
        return FALSE
    
    if(!size_list[positionkey])
        message_admins("No fitting spell found - aborting.")
        return FALSE
    message_admins("Success - returning keyed spell.")
    return size_list[positionkey]