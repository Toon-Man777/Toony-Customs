local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Union Roll Call
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Filter to find legal face-up targets on your field
function s.tgfilter(c,tp)
	return c:IsFaceup() and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil,c,tp)
end

-- FIXED: Replaced old CheckUnionEquip function with a modern aux.UnionFilter setup
function s.eqfilter(c,tc,tp)
	return c:IsType(TYPE_UNION) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and aux.UnionFilter(c,tc)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgfilter(chkc,tp) end
	-- Union Roll Call lets you target face-up monsters you control up to your available zones
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return false end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
	
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil,tp) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,ft,nil,tp)
	
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,#g,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,#g,tp,LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	if #g==0 then return end
	
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
	
	-- Only process monsters that can still have a Union monster equipped to them
	local tg=g:Filter(Card.IsFaceup,nil)
	if #tg==0 then return end
	
	local count=math.min(#tg, ft)
	local summoned=Group.CreateGroup()
	
	for tc in aux.Next(tg) do
		if count>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local eqg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.eqfilter),tp,LOCATION_GRAVE,0,1,1,nil,tc,tp)
			if #eqg>0 then
				local eqc=eqg:GetFirst()
				if Duel.SpecialSummonStep(eqc,0,tp,tp,false,false,POS_FACEUP) then
					-- Track successful summons to equip them afterward
					eqc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,tc:GetFieldID())
					summoned:AddCard(eqc)
					count=count-1
				end
			end
		end
	end
	Duel.SpecialSummonComplete()
	
	-- Perform the forced Union Equipment logic
	for eqc in aux.Next(summoned) do
		local fid=eqc:GetFlagEffectLabel(id)
		local tc=tg:Filter(function(c) return c:GetFieldID()==fid end, nil):GetFirst()
		if tc and tc:IsFaceup() and eqc:IsLocation(LOCATION_MZONE) then
			-- Equips the newly summoned Union monster directly out of the monster zone to its target
			Duel.Equip(tp,eqc,tc)
			aux.SetUnionState(eqc)
		end
	end
end