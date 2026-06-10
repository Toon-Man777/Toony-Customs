local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Add 1 "Mokey Mokey" from Deck/GY, then Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) -- Hard once per turn
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_names={27288416} -- Database ID for the original "Mokey Mokey"

-- Filter to find any "Mokey Mokey" monster (checks name and archetype)
function s.thfilter(c)
	return (c:IsCode(27288416) or string.find(c:GetOriginalName() or "","Mokey Mokey")~=nil) 
		and c:IsMonster() and c:IsAbleToHand()
end

-- Filter for checking valid Fusion Monsters in the Extra Deck
function s.ffilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) 
		and c:CheckFusionMaterial(m,nil,chkf)
end

-- Activation target tracking
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- Main execution function
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	
	-- If adding to hand succeeds, proceed
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		
		-- Essential break to re-evaluate hand data for the Fusion check
		Duel.BreakEffect()
		
		-- Setup Fusion values from Hand and Field
		local chkf=tp
		local m=Duel.GetFusionMaterial(tp):Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE)
		
		-- Look for playable "Mokey Mokey" Fusion options
		local fg=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp,m,nil,chkf)
		
		-- Prompt player to complete the Fusion Summon if available
		if #fg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tg=fg:Select(tp,1,1,nil)
			local tc=tg:GetFirst()
			if tc then
				local mat=Duel.SelectFusionMaterial(tp,tc,m,nil,chkf)
				tc:SetMaterial(mat)
				Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				Duel.BreakEffect()
				Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		end
	end
end