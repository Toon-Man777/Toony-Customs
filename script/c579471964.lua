local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Destroy 1 Fairy monster from field or hand, then add up to 2 "Mokey Mokey" monsters from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
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
function s.desfilter(c)
	-- Checks for a Fairy monster on your field or in your hand
	return c:IsRace(RACE_FAIRY) and (c:IsFaceup() or c:IsLocation(LOCATION_HAND))
end

function s.thfilter(c)
	-- Checks for a "Mokey Mokey" monster (or card treated as such) that can be added to hand
	return (c:IsCode(27288416) or c:IsSetCard(0x184)) and c:IsMonster() and c:IsAbleToHand()
end

-- Target Function
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) 
	end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- Operation Function
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	-- Select 1 Fairy monster to destroy from field or hand
	local dg=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil)
	if #dg>0 and Duel.Destroy(dg,REASON_EFFECT)~=0 then
		-- Check for "Mokey Mokey" monsters remaining in the Deck
		local thg=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
		if #thg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			-- Add up to 2 "Mokey Mokey" monsters from deck to hand
			local sg=thg:Select(tp,1,2,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end