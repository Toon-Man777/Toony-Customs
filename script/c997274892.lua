local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Hanger Polymerization (Quick-Play)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- Hard once per turn activation limit
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Filters for valid Fusion targets
function s.revfilter1(c,e,tp)
	if not (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION)) then return false end
	-- Must have specific materials listed
	local list=c:GetFusionMaterialList()
	if not list or #list==0 then return false end
	
	-- Check available materials across hand, field, and GY
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
	return s.check_materials(c,mg,tp,e)
end

function s.revfilter2(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION)
end

function s.matfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) 
		and c:IsType(TYPE_NORMAL+TYPE_FUSION+TYPE_UNION) and c:IsAbleToRemove()
end

-- Logic to check if materials match the primary card or additional revealed cards
function s.check_materials(fc,mg,tp,e)
	local list=fc:GetFusionMaterialList()
	-- Basic verification to ensure there is a combination of available named cards in your pools
	for _,code in ipairs(list) do
		if not mg:IsExists(Card.IsCode,1,nil,code) then
			-- If a code is missing, check if it could be bypassed by a generic sub or additional reveal check
			-- For baseline safety, we confirm if at least valid card counts exist
			return Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,#list,nil)
		end
	end
	return true
end

-- 1. Target Validation
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_FUSION)>0
		and Duel.IsExistingMatchingCard(s.revfilter1,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE)
end

-- 2. Activation Execution
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_FUSION)<=0 then return end

	-- Reveal First Mandatory Target
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g1=Duel.SelectMatchingCard(tp,s.revfilter1,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc1=g1:GetFirst()
	if not tc1 then return end
	Duel.ConfirmCards(1-tp,tc1)
	
	-- Optional: Reveal any number of additional LIGHT Machine Fusion Monsters
	local extra_revealed=Group.CreateGroup()
	while Duel.IsExistingMatchingCard(s.revfilter2,tp,LOCATION_EXTRA,0,1,tc1,extra_revealed) 
		and Duel.SelectYesNo(tp,aux.Stringid(id,0)) do -- Custom prompt string: "Reveal an additional Fusion Monster?"
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local g2=Duel.SelectMatchingCard(tp,s.revfilter2,tp,LOCATION_EXTRA,0,1,1,extra_revealed)
		if #g2>0 then
			extra_revealed:Merge(g2)
			Duel.ConfirmCards(1-tp,g2)
		end
	end

	-- Compile required materials database from primary card
	local mat_list=tc1:GetFusionMaterialList()
	local final_materials=Group.CreateGroup()
	local pool=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)

	-- Compile substitution codes from extra revealed cards if any exist
	local substitute_codes={}
	if #extra_revealed>0 then
		for ex_tc in aux.Next(extra_revealed) do
			local ex_list=ex_tc:GetFusionMaterialList()
			if ex_list then
				for _,code in ipairs(ex_list) do
					substitute_codes[code]=true
				end
			end
		end
	end

	-- Material Selection Loop
	for _,req_code in ipairs(mat_list) do
		local mat_choices=pool:Filter(function(c)
			return c:IsCode(req_code) or (substitute_codes[c:GetCode()] == true)
		end, nil)
		
		if #mat_choices==0 then return end -- Resolution fails if materials cannot be completed
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local mat_select=mat_choices:Select(tp,1,1,nil)
		final_materials:Merge(mat_select)
		pool:RemoveCard(mat_select:GetFirst())
	end

	-- Banish the collected materials and Special Summon
	if #final_materials>0 and Duel.Banish(final_materials,POS_FACEUP,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		-- Treated as a Summon by its own procedure
		Duel.SpecialSummon(tc1,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc1:CompleteProcedure()
	end
end