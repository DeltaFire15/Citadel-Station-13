/mob/living/carbon/human/get_typing_indicator_icon_state()
	return dna?.species?.get_typing_indicator_state() || ..()
