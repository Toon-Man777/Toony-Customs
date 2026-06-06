local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Add 1 "Mokey Mokey" monster from Deck/GY, then optionally Fusion Summon
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

s.listed_names={27288416} -- Original "Mokey Mokey" card code
s.listed_series={0x184}   -- "Mokey Mokey" archetype setcode

-- Filters
function s.thfilter(c)
	-- Searches or recovers a "Mokey Mokey" monster
	return (c:IsCode(27288416) or c:IsSetCard(0x184)) and c:IsMonster() and c:IsAbleToHand()
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Safe check to see if a legal Fusion Summon is possible using hand/field materials
	return Fusion.SummonEffTG(e,tp,eg,ep,ev,re,r,rp,chk)
end

-- Target Logic
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- Operation Logic
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	-- Add 1 "Mokey Mokey" monster from your Deck or GY to your hand
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		
		-- Then, you can Fusion Summon 1 from your Extra Deck
		local fusiong = Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_EXTRA,0,nil,TYPE_FUSION)
		if #fusiong>0 and s.fustg(e,tp,eg,ep,ev,re,r,rp,0) and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			-- Uses monsters from your hand or field as material
			Fusion.SummonEffOP(e,tp,eg,ep,ev,re,r,rp)
		end
	end
end