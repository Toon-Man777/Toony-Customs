local s,id=GetID()
function s.initial_effect(c)
	-- Negate effect or summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x200000+0x4000) -- CATEGORY_NEGATE+CATEGORY_DECKDES
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(4101) -- EVENT_CHAIN_SOLVING
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	
	local e2=e1:Clone()
	e2:SetCode(1011) -- EVENT_SPSUMMON_SUCCESS
	e2:SetCondition(s.sumcon)
	c:RegisterEffect(e2)

	-- Banish from GY to summon (Levels equal 6)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(0x1)
	e3:SetType(4) -- EFFECT_TYPE_IGNITION
	e3:SetRange(16) -- LOCATION_GRAVE
	e3:SetCountLimit(1,id+1)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- Negation Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- Controls 2 "Iron Chain" monsters
	return rp~=tp and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,4,0,2,nil,0x25)
		and Duel.IsChainNegatable(ev)
end
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return tp~=ep and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,4,0,2,nil,0x25)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,0x200000,eg,1,0,0)
	Duel.SetOperationInfo(0,0x4000,nil,0,1-tp,5)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) or Duel.NegateSummon(eg) then
		-- Send top 5 cards to GY
		Duel.DiscardDeck(1-tp,5,64)
	end
end

-- GY Summon Logic
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local g=Duel.GetMatchingGroup(s.spfilter,tp,1+16,0,nil,e,tp)
		return Duel.GetLocationCount(tp,4)>0 and g:CheckWithSumEqual(Card.GetLevel,6,1,2)
	end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,1+16)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,4)<=0 then return end
	local g=Duel.GetMatchingGroup(s.spfilter,tp,1+16,0,nil,e,tp)
	Duel.Hint(3,tp,509)
	local sg=g:SelectWithSumEqual(tp,Card.GetLevel,6,1,2)
	if #sg>0 then
		Duel.SpecialSummon(sg,0,tp,tp,false,false,1)
	end
end