--- STEAMODDED HEADER
--- MOD_NAME: View Deck Pages
--- MOD_ID: previewdeckpages
--- MOD_AUTHOR: [RattlingSnow353]
--- MOD_DESCRIPTION: View deck pages
--- BADGE_COLOUR: DF509F
--- DISPLAY_NAME: Deck Pages
--- VERSION: 0.1.0
--- PREFIX: pdp

----------------------------------------------
------------MOD CODE -------------------------
deck_config = SMODS.current_mod.config
local view_deck_unplayed_only = nil

function G.UIDEF.view_deck(unplayed_only)
	local deck_tables = {}
	remove_nils(G.playing_cards)
	G.VIEWING_DECK = true
	view_deck_unplayed_only = unplayed_only
	table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
	local SUITS = {}
	local suit_map = {}
	for i = #SMODS.Suit.obj_buffer, 1, -1 do
		SUITS[SMODS.Suit.obj_buffer[i]] = {}
		suit_map[#suit_map + 1] = SMODS.Suit.obj_buffer[i]
	end
	for k, v in ipairs(G.playing_cards) do
		if v.base.suit then table.insert(SUITS[v.base.suit], v) end
	end
	local num_suits = 0
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then num_suits = num_suits + 1 end
	end

	local visible_suit = {}
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then
			table.insert(visible_suit, suit_map[j])
		end
	end

	for j = 1, #visible_suit do
		if (j >= 1 and j <= 4) or num_suits <= 4 then
			if SUITS[visible_suit[j]][1] then
				local view_deck = CardArea(
					G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
					6.5 * G.CARD_W,
					(0.6) * G.CARD_H,
					{
						card_limit = #SUITS[visible_suit[j]],
						type = 'title',
						view_deck = true,
						highlight_limit = 0,
						card_w = G
							.CARD_W * 0.7,
						draw_layers = { 'card' }
					})
				table.insert(deck_tables,
					{n = G.UIT.R, config = {align = "cm", padding = 0}, nodes = {
						{n = G.UIT.O, config = {object = view_deck}}}}
				)
				for i = 1, #SUITS[visible_suit[j]] do
					if SUITS[visible_suit[j]][i] then
						local greyed, _scale = nil, 0.7
						if unplayed_only and not ((SUITS[visible_suit[j]][i].area and SUITS[visible_suit[j]][i].area == G.deck) or SUITS[visible_suit[j]][i].ability.wheel_flipped) then
							greyed = true
						end
						local copy = copy_card(SUITS[visible_suit[j]][i], nil, _scale)
						copy.greyed = greyed
						copy.T.x = view_deck.T.x + view_deck.T.w / 2
						copy.T.y = view_deck.T.y

						copy:hard_set_T()
						view_deck:emplace(copy)
					end
				end
			end
		end
	end

	if not next(deck_tables) then
		local view_deck = CardArea(
			G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
			6.5*G.CARD_W,
			0.6*G.CARD_H,
			{card_limit = 1, type = 'title', view_deck = true, highlight_limit = 0, card_w = G.CARD_W*0.7, draw_layers = {'card'}})
		table.insert(
			deck_tables,
			{n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
				{n=G.UIT.O, config={object = view_deck}}
			}}
		)
	end

	local flip_col = G.C.WHITE

	local suit_tallies = {}
	local mod_suit_tallies = {}
	for _, v in ipairs(suit_map) do
		suit_tallies[v] = 0
		mod_suit_tallies[v] = 0
	end
	local rank_tallies = {}
	local mod_rank_tallies = {}
	local rank_name_mapping = SMODS.Rank.obj_buffer
	for _, v in ipairs(rank_name_mapping) do
		rank_tallies[v] = 0
		mod_rank_tallies[v] = 0
	end
	local face_tally = 0
	local mod_face_tally = 0
	local num_tally = 0
	local mod_num_tally = 0
	local ace_tally = 0
	local mod_ace_tally = 0
	local wheel_flipped = 0

	for k, v in ipairs(G.playing_cards) do
		if v.ability.name ~= 'Stone Card' and (not unplayed_only or ((v.area and v.area == G.deck) or v.ability.wheel_flipped)) then
			if v.ability.wheel_flipped and not (v.area and v.area == G.deck) and unplayed_only then wheel_flipped = wheel_flipped + 1 end
			--For the suits
			if v.base.suit then suit_tallies[v.base.suit] = (suit_tallies[v.base.suit] or 0) + 1 end
			for kk, vv in pairs(mod_suit_tallies) do
				mod_suit_tallies[kk] = (vv or 0) + (v:is_suit(kk) and 1 or 0)
			end

			--for face cards/numbered cards/aces
			local card_id = v:get_id()
			if v.base.value then face_tally = face_tally + ((SMODS.Ranks[v.base.value].face) and 1 or 0) end
			mod_face_tally = mod_face_tally + (v:is_face() and 1 or 0)
			if v.base.value and not SMODS.Ranks[v.base.value].face and card_id ~= 14 then
				num_tally = num_tally + 1
				if not v.debuff then mod_num_tally = mod_num_tally + 1 end
			end
			if card_id == 14 then
				ace_tally = ace_tally + 1
				if not v.debuff then mod_ace_tally = mod_ace_tally + 1 end
			end

			--ranks
			if v.base.value then rank_tallies[v.base.value] = rank_tallies[v.base.value] + 1 end
			if v.base.value and not v.debuff then mod_rank_tallies[v.base.value] = mod_rank_tallies[v.base.value] + 1 end
		end
	end
	local modded = face_tally ~= mod_face_tally
	for kk, vv in pairs(mod_suit_tallies) do
		modded = modded or (vv ~= suit_tallies[kk])
		if modded then break end
	end

	if wheel_flipped > 0 then flip_col = mix_colours(G.C.FILTER, G.C.WHITE, 0.7) end

	local rank_cols = {}
	for i = #rank_name_mapping, 1, -1 do
		if rank_tallies[rank_name_mapping[i]] ~= 0 or not SMODS.Ranks[rank_name_mapping[i]].in_pool or SMODS.Ranks[rank_name_mapping[i]]:in_pool({suit=''}) then
			local mod_delta = mod_rank_tallies[rank_name_mapping[i]] ~= rank_tallies[rank_name_mapping[i]]
			rank_cols[#rank_cols + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.07}, nodes = {
				{n = G.UIT.C, config = {align = "cm", r = 0.1, padding = 0.04, emboss = 0.04, minw = 0.5, colour = G.C.L_BLACK}, nodes = {
					{n = G.UIT.T, config = {text = SMODS.Ranks[rank_name_mapping[i]].shorthand, colour = G.C.JOKER_GREY, scale = 0.35, shadow = true}},}},
				{n = G.UIT.C, config = {align = "cr", minw = 0.4}, nodes = {
					mod_delta and {n = G.UIT.O, config = {
							object = DynaText({
								string = { { string = '' .. rank_tallies[rank_name_mapping[i]], colour = flip_col }, { string = '' .. mod_rank_tallies[rank_name_mapping[i]], colour = G.C.BLUE } },
								colours = { G.C.RED }, scale = 0.4, y_offset = -2, silent = true, shadow = true, pop_in_rate = 10, pop_delay = 4
							})}}
					or {n = G.UIT.T, config = {text = rank_tallies[rank_name_mapping[i]], colour = flip_col, scale = 0.45, shadow = true } },}}}}
		end
	end

	local tally_ui = {
		-- base cards
		{n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.07}, nodes = {
			{n = G.UIT.O, config = {
					object = DynaText({
						string = {
							{ string = localize('k_base_cards'), colour = G.C.RED },
							modded and { string = localize('k_effective'), colour = G.C.BLUE } or nil
						},
						colours = { G.C.RED }, silent = true, scale = 0.4, pop_in_rate = 10, pop_delay = 4
					})
				}}}},
		-- aces, faces and numbered cards
		{n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.1}, nodes = {
			tally_sprite(
				{ x = 1, y = 0 },
				{ { string = '' .. ace_tally, colour = flip_col }, { string = '' .. mod_ace_tally, colour = G.C.BLUE } },
				{ localize('k_aces') }
			), --Aces
			tally_sprite(
				{ x = 2, y = 0 },
				{ { string = '' .. face_tally, colour = flip_col }, { string = '' .. mod_face_tally, colour = G.C.BLUE } },
				{ localize('k_face_cards') }
			), --Face
			tally_sprite(
				{ x = 3, y = 0 },
				{ { string = '' .. num_tally, colour = flip_col }, { string = '' .. mod_num_tally, colour = G.C.BLUE } },
				{ localize('k_numbered_cards') }
			), --Numbers
		}},
	}
	-- add suit tallies
	local hidden_suits = {}
	for _, suit in ipairs(suit_map) do
		if suit_tallies[suit] == 0 and SMODS.Suits[suit].in_pool and not SMODS.Suits[suit]:in_pool({rank=''}) then
			hidden_suits[suit] = true
		end
	end
	local i = 1
	local num_suits_shown = 0
	for i = 1, #suit_map do
		if not hidden_suits[suit_map[i]] then
			num_suits_shown = num_suits_shown+1
		end
	end
	local suits_per_row = 2
	local n_nodes = {}
	local visible_suits = {}
	local temp_list = {}
	while i <= #suit_map do
		while #n_nodes < suits_per_row and i <= #suit_map do
			if not hidden_suits[suit_map[i]] then
				table.insert(n_nodes, tally_sprite(
					SMODS.Suits[suit_map[i]].ui_pos,
					{
						{ string = '' .. suit_tallies[suit_map[i]], colour = flip_col },
						{ string = '' .. mod_suit_tallies[suit_map[i]], colour = G.C.BLUE }
					},
					{ localize(suit_map[i], 'suits_plural') },
					suit_map[i]
				))
				table.insert(visible_suits, i)
			end
			i = i + 1
		end
		if #n_nodes > 0 then
			for i = 1, #n_nodes do
				table.insert(temp_list, n_nodes[i])
			end
			n_nodes = {}
		end
	end

	local index = 0
	local second_temp_list = {}
	for _, v in ipairs(temp_list) do
		local start_index = (1 - 1) * 4 + 1
		local end_index = math.min(start_index + 4 - 1, #temp_list)
    
		local t_list = {}
		for i = start_index, end_index do
			table.insert(t_list, temp_list[i])
		end

		second_temp_list = {}
		for i = 1, #t_list do
			table.insert(second_temp_list, t_list[i])
		end
	end

	if #second_temp_list > 0 then
		local n = {n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.1}, nodes = second_temp_list}
		table.insert(tally_ui, n)
		second_temp_list = {}
	end

	local suit_options = {}
	for i = 1, math.ceil(#visible_suits / 4) do
		table.insert(suit_options,
			localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_suits / 4)))
	end

	local object = {n = G.UIT.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes = {
		{n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {}},
		{n = G.UIT.R, config = {align = "cm"}, nodes = {
			{n = G.UIT.C, config = {align = "cm", minw = 1.5, minh = 2, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes = {
				{n = G.UIT.C, config = {align = "cm", padding = 0.1}, nodes = {
					{n = G.UIT.R, config = {align = "cm", r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, padding = 0.15}, nodes = {
						{n = G.UIT.R, config = {align = "cm"}, nodes = {
							{n = G.UIT.O, config = {
									object = DynaText({ string = G.GAME.selected_back.loc_name, colours = {G.C.WHITE}, bump = true, rotate = true, shadow = true, scale = 0.6 - string.len(G.GAME.selected_back.loc_name) * 0.01 })
								}},}},
						{n = G.UIT.R, config = {align = "cm", r = 0.1, padding = 0.1, minw = 2.5, minh = 1.3, colour = G.C.WHITE, emboss = 0.05}, nodes = {
							{n = G.UIT.O, config = {
									object = UIBox {
										definition = G.GAME.selected_back:generate_UI(nil, 0.7, 0.5, G.GAME.challenge), config = {offset = { x = 0, y = 0 } }
									}
								}}}}}},
					{n = G.UIT.R, config = {align = "cm", r = 0.1, outline_colour = G.C.L_BLACK, line_emboss = 0.05, outline = 1.5}, nodes =
						tally_ui}}},
				{n = G.UIT.C, config = {align = "cm"}, nodes = rank_cols},
				{n = G.UIT.B, config = {w = 0.1, h = 0.1}},}},
			{n = G.UIT.B, config = {w = 0.2, h = 0.1}},
			{n = G.UIT.C, config = {align = "cm", padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes =
				deck_tables}}},
		{n = G.UIT.R, config = {align = "cm", padding = 0 }, nodes = {
				create_option_cycle({
					options = suit_options,
					w = 4.5,
					cycle_shoulders = true,
					opt_callback =
					'your_suits_page',
					focus_args = { snap_to = true, nav = 'wide' },
					current_option = 1,
					colour = G
						.C.RED,
					no_pips = true,
				})
			}
		},
		{n = G.UIT.R, config = {align = "cm", minh = 0.8, padding = 0}, nodes = {
			modded and {n = G.UIT.R, config = {align = "cm"}, nodes = {
				{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7)}, nodes = {}},
				{n = G.UIT.T, config = {text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3}},}}
			or nil,
			wheel_flipped > 0 and {n = G.UIT.R, config = {align = "cm"}, nodes = {
				{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = flip_col}, nodes = {}},
				{n = G.UIT.T, config = {
						text = ' ' .. (wheel_flipped > 1 and
							localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
							localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
						colour = G.C.WHITE, scale = 0.3
					}},}}
			or nil,}}}}
	local t = {n = G.UIT.ROOT, config = {align = "cm", minw = 3, padding = 0.1, r = 0.1, colour = G.C.CLEAR}, nodes = {
		{n = G.UIT.O, config = {
				id = 'suit_list',
				object = UIBox {
					definition = object, config = {offset = { x = 0, y = 0 }, align = 'cm'}
				}
			}}}}
	return t
end

G.FUNCS.your_suits_page = function(args)
	if not args or not args.cycle_config then return end
	local deck_tables = {}
	remove_nils(G.playing_cards)
	G.VIEWING_DECK = true
	table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
	local SUITS = {}
	local suit_map = {} 
	for i = #SMODS.Suit.obj_buffer, 1, -1 do
		SUITS[SMODS.Suit.obj_buffer[i]] = {}
		suit_map[#suit_map + 1] = SMODS.Suit.obj_buffer[i]
	end
	for k, v in ipairs(G.playing_cards) do
		if v.base.suit then table.insert(SUITS[v.base.suit], v) end
	end
	local num_suits = 0
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then num_suits = num_suits + 1 end
	end

	local visible_suit = {}
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then
			table.insert(visible_suit, suit_map[j])
		end
	end

	local deck_start_index = (args.cycle_config.current_option - 1) * 4 + 1
	local deck_end_index = math.min(deck_start_index + 4 - 1, #visible_suit)
	for j = 1, #visible_suit do
		if SUITS[visible_suit[j]][1] and (j >= deck_start_index and j <= deck_end_index) then
			local view_deck = CardArea(
				G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
				6.5 * G.CARD_W,
				(0.6) * G.CARD_H,
				{
					card_limit = #SUITS[visible_suit[j]],
					type = 'title',
					view_deck = true,
					highlight_limit = 0,
					card_w = G
						.CARD_W * 0.7,
					draw_layers = { 'card' }
				})
			table.insert(deck_tables,
				{n = G.UIT.R, config = {align = "cm", padding = 0}, nodes = {
					{n = G.UIT.O, config = {object = view_deck}}}}
			)
			for i = 1, #SUITS[visible_suit[j]] do
				if SUITS[visible_suit[j]][i] then
					local greyed, _scale = nil, 0.7
					if view_deck_unplayed_only and not ((SUITS[visible_suit[j]][i].area and SUITS[visible_suit[j]][i].area == G.deck) or SUITS[visible_suit[j]][i].ability.wheel_flipped) then
						greyed = true
					end
					local copy = copy_card(SUITS[visible_suit[j]][i], nil, _scale)
					copy.greyed = greyed
					copy.T.x = view_deck.T.x + view_deck.T.w / 2
					copy.T.y = view_deck.T.y

					copy:hard_set_T()
					view_deck:emplace(copy)
				end
			end
		end
	end

	if not next(deck_tables) then
		local view_deck = CardArea(
			G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
			6.5*G.CARD_W,
			0.6*G.CARD_H,
			{card_limit = 1, type = 'title', view_deck = true, highlight_limit = 0, card_w = G.CARD_W*0.7, draw_layers = {'card'}})
		table.insert(
			deck_tables,
			{n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
				{n=G.UIT.O, config={object = view_deck}}
			}}
		)
	end

	local flip_col = G.C.WHITE

	local suit_tallies = {}
	local mod_suit_tallies = {}
	for _, v in ipairs(suit_map) do
		suit_tallies[v] = 0
		mod_suit_tallies[v] = 0
	end
	local rank_tallies = {}
	local mod_rank_tallies = {}
	local rank_name_mapping = SMODS.Rank.obj_buffer
	for _, v in ipairs(rank_name_mapping) do
		rank_tallies[v] = 0
		mod_rank_tallies[v] = 0
	end
	local face_tally = 0
	local mod_face_tally = 0
	local num_tally = 0
	local mod_num_tally = 0
	local ace_tally = 0
	local mod_ace_tally = 0
	local wheel_flipped = 0

	for k, v in ipairs(G.playing_cards) do
		if v.ability.name ~= 'Stone Card' and (not view_deck_unplayed_only or ((v.area and v.area == G.deck) or v.ability.wheel_flipped)) then
			if v.ability.wheel_flipped and not (v.area and v.area == G.deck) and view_deck_unplayed_only then wheel_flipped = wheel_flipped + 1 end
			--For the suits
			if v.base.suit then suit_tallies[v.base.suit] = (suit_tallies[v.base.suit] or 0) + 1 end
			for kk, vv in pairs(mod_suit_tallies) do
				mod_suit_tallies[kk] = (vv or 0) + (v:is_suit(kk) and 1 or 0)
			end

			--for face cards/numbered cards/aces
			local card_id = v:get_id()
			if v.base.value then face_tally = face_tally + ((SMODS.Ranks[v.base.value].face) and 1 or 0) end
			mod_face_tally = mod_face_tally + (v:is_face() and 1 or 0)
			if v.base.value and not SMODS.Ranks[v.base.value].face and card_id ~= 14 then
				num_tally = num_tally + 1
				if not v.debuff then mod_num_tally = mod_num_tally + 1 end
			end
			if card_id == 14 then
				ace_tally = ace_tally + 1
				if not v.debuff then mod_ace_tally = mod_ace_tally + 1 end
			end

			--ranks
			if v.base.value then rank_tallies[v.base.value] = rank_tallies[v.base.value] + 1 end
			if v.base.value and not v.debuff then mod_rank_tallies[v.base.value] = mod_rank_tallies[v.base.value] + 1 end
		end
	end
	local modded = face_tally ~= mod_face_tally
	for kk, vv in pairs(mod_suit_tallies) do
		modded = modded or (vv ~= suit_tallies[kk])
		if modded then break end
	end

	if wheel_flipped > 0 then flip_col = mix_colours(G.C.FILTER, G.C.WHITE, 0.7) end

	local rank_cols = {}
	for i = #rank_name_mapping, 1, -1 do
		if rank_tallies[rank_name_mapping[i]] ~= 0 or not SMODS.Ranks[rank_name_mapping[i]].in_pool or SMODS.Ranks[rank_name_mapping[i]]:in_pool({suit=''}) then
			local mod_delta = mod_rank_tallies[rank_name_mapping[i]] ~= rank_tallies[rank_name_mapping[i]]
			rank_cols[#rank_cols + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.07}, nodes = {
				{n = G.UIT.C, config = {align = "cm", r = 0.1, padding = 0.04, emboss = 0.04, minw = 0.5, colour = G.C.L_BLACK}, nodes = {
					{n = G.UIT.T, config = {text = SMODS.Ranks[rank_name_mapping[i]].shorthand, colour = G.C.JOKER_GREY, scale = 0.35, shadow = true}},}},
				{n = G.UIT.C, config = {align = "cr", minw = 0.4}, nodes = {
					mod_delta and {n = G.UIT.O, config = {
							object = DynaText({
								string = { { string = '' .. rank_tallies[rank_name_mapping[i]], colour = flip_col }, { string = '' .. mod_rank_tallies[rank_name_mapping[i]], colour = G.C.BLUE } },
								colours = { G.C.RED }, scale = 0.4, y_offset = -2, silent = true, shadow = true, pop_in_rate = 10, pop_delay = 4
							})}}
					or {n = G.UIT.T, config = {text = rank_tallies[rank_name_mapping[i]], colour = flip_col, scale = 0.45, shadow = true } },}}}}
		end
	end

	local tally_ui = {
		-- base cards
		{n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.07}, nodes = {
			{n = G.UIT.O, config = {
					object = DynaText({
						string = {
							{ string = localize('k_base_cards'), colour = G.C.RED },
							modded and { string = localize('k_effective'), colour = G.C.BLUE } or nil
						},
						colours = { G.C.RED }, silent = true, scale = 0.4, pop_in_rate = 10, pop_delay = 4
					})
				}}}},
		-- aces, faces and numbered cards
		{n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.1}, nodes = {
			tally_sprite(
				{ x = 1, y = 0 },
				{ { string = '' .. ace_tally, colour = flip_col }, { string = '' .. mod_ace_tally, colour = G.C.BLUE } },
				{ localize('k_aces') }
			), --Aces
			tally_sprite(
				{ x = 2, y = 0 },
				{ { string = '' .. face_tally, colour = flip_col }, { string = '' .. mod_face_tally, colour = G.C.BLUE } },
				{ localize('k_face_cards') }
			), --Face
			tally_sprite(
				{ x = 3, y = 0 },
				{ { string = '' .. num_tally, colour = flip_col }, { string = '' .. mod_num_tally, colour = G.C.BLUE } },
				{ localize('k_numbered_cards') }
			), --Numbers
		}},
	}
	-- add suit tallies
	local hidden_suits = {}
	for _, suit in ipairs(suit_map) do
		if suit_tallies[suit] == 0 and SMODS.Suits[suit].in_pool and not SMODS.Suits[suit]:in_pool({rank=''}) then
			hidden_suits[suit] = true
		end
	end
	local i = 1
	local num_suits_shown = 0
	for i = 1, #suit_map do
		if not hidden_suits[suit_map[i]] then
			num_suits_shown = num_suits_shown+1
		end
	end
	local suits_per_row = 2
	local n_nodes = {}
	local visible_suits = {}
	local temp_list = {}
	while i <= #suit_map do
		while #n_nodes < suits_per_row and i <= #suit_map do
			if not hidden_suits[suit_map[i]] then
				table.insert(n_nodes, tally_sprite(
					SMODS.Suits[suit_map[i]].ui_pos,
					{
						{ string = '' .. suit_tallies[suit_map[i]], colour = flip_col },
						{ string = '' .. mod_suit_tallies[suit_map[i]], colour = G.C.BLUE }
					},
					{ localize(suit_map[i], 'suits_plural') },
					suit_map[i]
				))
				table.insert(visible_suits, i)
			end
			i = i + 1
		end
		if #n_nodes > 0 then
			for i = 1, #n_nodes do
				table.insert(temp_list, n_nodes[i])
			end
			n_nodes = {}
		end
	end

	local index = 0
	local second_temp_list = {}
	for _, v in ipairs(temp_list) do
		local start_index = (args.cycle_config.current_option - 1) * 4 + 1
		local end_index = math.min(start_index + 4 - 1, #temp_list)
    
		local t_list = {}
		for i = start_index, end_index do
			table.insert(t_list, temp_list[i])
		end

		second_temp_list = {}
		for i = 1, #t_list do
			table.insert(second_temp_list, t_list[i])
		end
	end

	if #second_temp_list > 0 then
		local n = {n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.1}, nodes = second_temp_list}
		table.insert(tally_ui, n)
		second_temp_list = {}
	end

	local suit_options = {}
	for i = 1, math.ceil(#visible_suits / 4) do
		table.insert(suit_options,
			localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_suits / 4)))
	end

	local object = {n = G.UIT.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes = {
		{n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {}},
		{n = G.UIT.R, config = {align = "cm"}, nodes = {
			{n = G.UIT.C, config = {align = "cm", minw = 1.5, minh = 2, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes = {
				{n = G.UIT.C, config = {align = "cm", padding = 0.1}, nodes = {
					{n = G.UIT.R, config = {align = "cm", r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, padding = 0.15}, nodes = {
						{n = G.UIT.R, config = {align = "cm"}, nodes = {
							{n = G.UIT.O, config = {
									object = DynaText({ string = G.GAME.selected_back.loc_name, colours = {G.C.WHITE}, bump = true, rotate = true, shadow = true, scale = 0.6 - string.len(G.GAME.selected_back.loc_name) * 0.01 })
								}},}},
						{n = G.UIT.R, config = {align = "cm", r = 0.1, padding = 0.1, minw = 2.5, minh = 1.3, colour = G.C.WHITE, emboss = 0.05}, nodes = {
							{n = G.UIT.O, config = {
									object = UIBox {
										definition = G.GAME.selected_back:generate_UI(nil, 0.7, 0.5, G.GAME.challenge), config = {offset = { x = 0, y = 0 } }
									}
								}}}}}},
					{n = G.UIT.R, config = {align = "cm", r = 0.1, outline_colour = G.C.L_BLACK, line_emboss = 0.05, outline = 1.5}, nodes =
						tally_ui}}},
				{n = G.UIT.C, config = {align = "cm"}, nodes = rank_cols},
				{n = G.UIT.B, config = {w = 0.1, h = 0.1}},}},
			{n = G.UIT.B, config = {w = 0.2, h = 0.1}},
			{n = G.UIT.C, config = {align = "cm", padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes =
				deck_tables}}},
		{n = G.UIT.R, config = {align = "cm", padding = 0 }, nodes = {
				create_option_cycle({
					options = suit_options,
					w = 4.5,
					cycle_shoulders = true,
					opt_callback =
					'your_suits_page',
					focus_args = { snap_to = true, nav = 'wide' },
					current_option = args.cycle_config.current_option,
					colour = G
						.C.RED,
					no_pips = true,
				})
			}
		},
		{n = G.UIT.R, config = {align = "cm", minh = 0.8, padding = 0.05}, nodes = {
			modded and {n = G.UIT.R, config = {align = "cm"}, nodes = {
				{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7)}, nodes = {}},
				{n = G.UIT.T, config = {text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3}},}}
			or nil,
			wheel_flipped > 0 and {n = G.UIT.R, config = {align = "cm"}, nodes = {
				{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = flip_col}, nodes = {}},
				{n = G.UIT.T, config = {
						text = ' ' .. (wheel_flipped > 1 and
							localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
							localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
						colour = G.C.WHITE, scale = 0.3
					}},}}
			or nil,}}}}

	local suit_list = G.OVERLAY_MENU:get_UIE_by_ID('suit_list')
	if suit_list then
		if suit_list.config.object then
			suit_list.config.object:remove()
		end
		suit_list.config.object = UIBox {
			definition = object, config = {offset = { x = 0, y = 0 }, align = 'cm', parent = suit_list }
		}
	end
end

if deck_config.lag_be_gone then
	function G.UIDEF.deck_preview(args)
		local _minh, _minw = 0.35, 0.5
		local suit_labels = {}
		local suit_counts = {}
		local mod_suit_counts = {}
		for _, v in ipairs(SMODS.Suit.obj_buffer) do
			suit_counts[v] = 0
			mod_suit_counts[v] = 0
		end
		local mod_suit_diff = false
		local wheel_flipped, wheel_flipped_text = 0, nil
		local flip_col = G.C.WHITE
		local rank_counts = {}
		local deck_tables = {}
		remove_nils(G.playing_cards)
		table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
		local SUITS = {}
		for _, suit in ipairs(SMODS.Suit.obj_buffer) do
			SUITS[suit] = {}
			for _, rank in ipairs(SMODS.Rank.obj_buffer) do
				SUITS[suit][rank] = {}
			end
		end
		local stones = nil
		local suit_map = {}
		for i = #SMODS.Suit.obj_buffer, 1, -1 do
			suit_map[#suit_map + 1] = SMODS.Suit.obj_buffer[i]
		end
		local rank_name_mapping = {}
		for i = #SMODS.Rank.obj_buffer, 1, -1 do
			rank_name_mapping[#rank_name_mapping + 1] = SMODS.Rank.obj_buffer[i]
		end
		for k, v in ipairs(G.playing_cards) do
			if v.ability.effect == 'Stone Card' then
				stones = stones or 0
			end
			if (v.area and v.area == G.deck) or v.ability.wheel_flipped then
				if v.ability.wheel_flipped and not (v.area and v.area == G.deck) then wheel_flipped = wheel_flipped + 1 end
				if v.ability.effect == 'Stone Card' then
					stones = stones + 1
				else
					for kk, vv in pairs(suit_counts) do
						if v.base.suit == kk then suit_counts[kk] = suit_counts[kk] + 1 end
						if v:is_suit(kk) then mod_suit_counts[kk] = mod_suit_counts[kk] + 1 end
					end
					if SUITS[v.base.suit][v.base.value] then
						table.insert(SUITS[v.base.suit][v.base.value], v)
					end
					rank_counts[v.base.value] = (rank_counts[v.base.value] or 0) + 1
				end
			end
		end

		wheel_flipped_text = (wheel_flipped > 0) and
			{n = G.UIT.T, config = {text = '?', colour = G.C.FILTER, scale = 0.25, shadow = true}}
		or nil
		flip_col = wheel_flipped_text and mix_colours(G.C.FILTER, G.C.WHITE, 0.7) or G.C.WHITE

		suit_labels[#suit_labels + 1] = {n = G.UIT.R, config = {align = "cm", r = 0.1, padding = 0.04, minw = _minw, minh = 2 * _minh + 0.25}, nodes = {
			stones and {n = G.UIT.T, config = {text = localize('ph_deck_preview_stones') .. ': ', colour = G.C.WHITE, scale = 0.25, shadow = true}}
			or nil,
			stones and {n = G.UIT.T, config = {text = '' .. stones, colour = (stones > 0 and G.C.WHITE or G.C.UI.TRANSPARENT_LIGHT), scale = 0.4, shadow = true}}
			or nil,}}
		local hidden_ranks = {}
		for _, rank in ipairs(rank_name_mapping) do
			local count = 0
			for _, suit in ipairs(suit_map) do
				count = count + #SUITS[suit][rank]
			end
			if count == 0 and SMODS.Ranks[rank].in_pool and not SMODS.Ranks[rank]:in_pool({suit=''}) then
				hidden_ranks[rank] = true
			end
		end
		local hidden_suits = {}
		for _, suit in ipairs(suit_map) do
			if suit_counts[suit] == 0 and SMODS.Suits[suit].in_pool and not SMODS.Suits[suit]:in_pool({rank=''}) then
				hidden_suits[suit] = true
			end
		end
		local _row = {}
		local _bg_col = G.C.JOKER_GREY
		for k, v in ipairs(rank_name_mapping) do
			local _tscale = 0.3
			local _colour = G.C.BLACK
			local rank_col = SMODS.Ranks[v].face and G.C.WHITE or _bg_col
			rank_col = mix_colours(rank_col, _bg_col, 0.8)

			local _col = {n = G.UIT.C, config = {align = "cm" }, nodes = {
				{n = G.UIT.C, config = {align = "cm", r = 0.1, minw = _minw, minh = _minh, colour = rank_col, emboss = 0.04, padding = 0.03 }, nodes = {
					{n = G.UIT.R, config = {align = "cm" }, nodes = {
						{n = G.UIT.T, config = {text = '' .. SMODS.Ranks[v].shorthand, colour = _colour, scale = 1.6 * _tscale } },}},
					{n = G.UIT.R, config = {align = "cm", minw = _minw + 0.04, minh = _minh, colour = G.C.L_BLACK, r = 0.1 }, nodes = {
						{n = G.UIT.T, config = {text = '' .. (rank_counts[v] or 0), colour = flip_col, scale = _tscale, shadow = true } }}}}}}}
			if not hidden_ranks[v] then table.insert(_row, _col) end
		end
		table.insert(deck_tables, {n = G.UIT.R, config = {align = "cm", padding = 0.04 }, nodes = _row })

		for _, suit in ipairs(suit_map) do
			if not hidden_suits[suit] and _ <= 4 then
				_row = {}
				_bg_col = mix_colours(G.C.SUITS[suit], G.C.L_BLACK, 0.7)
				for _, rank in ipairs(rank_name_mapping) do
					local _tscale = #SUITS[suit][rank] > 0 and 0.3 or 0.25
					local _colour = #SUITS[suit][rank] > 0 and flip_col or G.C.UI.TRANSPARENT_LIGHT

					local _col = {n = G.UIT.C, config = {align = "cm", padding = 0.05, minw = _minw + 0.098, minh = _minh }, nodes = {
						{n = G.UIT.T, config = {text = '' .. #SUITS[suit][rank], colour = _colour, scale = _tscale, shadow = true, lang = G.LANGUAGES['en-us'] } },}}
					if not hidden_ranks[rank] then table.insert(_row, _col) end
				end
				table.insert(deck_tables,
					{n = G.UIT.R, config = {align = "cm", r = 0.1, padding = 0.04, minh = 0.4, colour = _bg_col }, nodes =
						_row})
			end
		end

		for k, v in ipairs(suit_map) do
			if not hidden_suits[v] and k <= 4 then
				local deckskin = SMODS.DeckSkins[G.SETTINGS.CUSTOM_DECK.Collabs[v]]
				local palette = deckskin.palette_map and deckskin.palette_map[G.SETTINGS.colour_palettes[v] or ''] or (deckskin.palettes or {})[1]
				local t_s
				if palette and palette.suit_icon and palette.suit_icon.atlas then
					local _x = (v == 'Spades' and 3) or (v == 'Hearts' and 0) or (v == 'Clubs' and 2) or (v == 'Diamonds' and 1)
					t_s = Sprite(0,0,0.3,0.3,G.ASSET_ATLAS[palette.suit_icon.atlas or 'ui_1'], (type(palette.suit_icon.pos) == "number" and {x=_x, y=palette.suit_icon.pos}) or palette.suit_icon.pos or {x=_x, y=0})
				elseif G.SETTINGS.colour_palettes[v] == 'lc' or G.SETTINGS.colour_palettes[v] == 'hc' then
					t_s = Sprite(0, 0, 0.3, 0.3,
							G.ASSET_ATLAS[SMODS.Suits[v][G.SETTINGS.colour_palettes[v] == 'hc' and "hc_ui_atlas" or G.SETTINGS.colour_palettes[v] == 'lc' and "lc_ui_atlas"]] or
							G.ASSET_ATLAS[("ui_" .. (G.SETTINGS.colourblind_option and "2" or "1"))], SMODS.Suits[v].ui_pos)
				else
					t_s = Sprite(0, 0, 0.3, 0.3, G.ASSET_ATLAS[("ui_" .. (G.SETTINGS.colourblind_option and "2" or "1"))], SMODS.Suits[v].ui_pos)
				end

				t_s.states.drag.can = false
				t_s.states.hover.can = false
				t_s.states.collide.can = false

				if mod_suit_counts[v] ~= suit_counts[v] then mod_suit_diff = true end

				suit_labels[#suit_labels + 1] =
				{n = G.UIT.R, config = {align = "cm", r = 0.1, padding = 0.03, colour = G.C.JOKER_GREY }, nodes = {
					{n = G.UIT.C, config = {align = "cm", minw = _minw, minh = _minh }, nodes = {
						{n = G.UIT.O, config = {can_collide = false, object = t_s } }}},
					{n = G.UIT.C, config = {align = "cm", minw = _minw * 2.4, minh = _minh, colour = G.C.L_BLACK, r = 0.1 }, nodes = {
						{n = G.UIT.T, config = {text = '' .. suit_counts[v], colour = flip_col, scale = 0.3, shadow = true, lang = G.LANGUAGES['en-us'] } },
						mod_suit_counts[v] ~= suit_counts[v] and {n = G.UIT.T, config = {text = ' (' .. mod_suit_counts[v] .. ')', colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7), scale = 0.28, shadow = true, lang = G.LANGUAGES['en-us'] } }
						or nil,}}}}
			end
		end


		local t = {n = G.UIT.ROOT, config = {align = "cm", colour = G.C.JOKER_GREY, r = 0.1, emboss = 0.05, padding = 0.07}, nodes = {
			{n = G.UIT.R, config = {align = "cm", r = 0.1, emboss = 0.05, colour = G.C.BLACK, padding = 0.1}, nodes = {
				{n = G.UIT.R, config = {align = "cm"}, nodes = {
					{n = G.UIT.C, config = {align = "cm", padding = 0.04}, nodes = suit_labels },
					{n = G.UIT.C, config = {align = "cm", padding = 0.02}, nodes = deck_tables }}},
				mod_suit_diff and {n = G.UIT.R, config = {align = "cm" }, nodes = {
					{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7) }, nodes = {} },
					{n = G.UIT.T, config = {text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3 } },}}
				or nil,
				wheel_flipped_text and {n = G.UIT.R, config = {align = "cm" }, nodes = {
					{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = flip_col }, nodes = {} },
					{n = G.UIT.T, config = {
							text = ' ' .. (wheel_flipped > 1 and
								localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
								localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
							colour = G.C.WHITE,
							scale = 0.3}},}}
				or nil,}}}}
		return t
	end
end

local text_scale = 0.9
SMODS.current_mod.config_tab = function()
  return {
    n = G.UIT.ROOT,
    config = {
      align = "tm",
      padding = 0.2,
      minw = 8,
      minh = 2,
      colour = G.C.BLACK,
      r = 0.1,
      hover = true,
      shadow = true,
      emboss = 0.05
    },
    nodes = {
      {
        n = G.UIT.R,
        config = { padding = 0, align = "cm", minh = 0.1 },
        nodes = {
          {
            n = G.UIT.C,
            config = { align = "c", padding = 0, minh = 0.1 },
            nodes = {
              {
                n = G.UIT.R,
                config = { padding = 0, align = "cm", minh = 0 },
                nodes = {
                  { n = G.UIT.T, config = { text = "Lag be Gone:", scale = 0.45, colour = G.C.UI.TEXT_LIGHT } },
                }
              },
            }
          },
          {
            n = G.UIT.C,
            config = { align = "cl", padding = 0.05 },
            nodes = {
              create_toggle { col = true, label = "", scale = 1, w = 0, shadow = true, ref_table = sigil_config, ref_value = "lag_be_gone" },
            }
          },
        }
      },

    }
  }
end

----------------------------------------------
------------MOD CODE END---------------------