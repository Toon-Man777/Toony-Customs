local s,id=GetID()
function s.initial_effect(c)
	-- Negate Spell/Trap activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x200000+0x4000) -- CATEGORY_NEGATE + CATEGORY_DECKDES
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(4101) -- EVENT_CHAINING
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- Negate Monster Summon
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x200000+0x4000)
	e2:SetType(0x10000)
	e2:SetCode(1011) -- EVENT_SPSUMMON
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.sumcon)
	e2:SetTarget(s.sumtg)
	e2:SetOperation(s.sumop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(1012) -- EVENT_SUMMON
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(1014) -- EVENT_FLIP_SUMMON
	c:RegisterEffect(e4)

	-- Banish from GY: Special Summon up to 2 "Iron Chain" from GY
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(0x1) -- CATEGORY_SPECIAL_SUMMON
	e5:SetType(4) -- EFFECT_TYPE_IGNITION
	e5:SetRange(16) -- LOCATION_GRAVE
	e5:SetCountLimit(1,id+1) -- Each effect once per turn
	e5:SetCost(aux.bfgcost)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop)
	c:RegisterEffect(e5)
end

-- Negate Spell/Trap Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev) and (re:IsActiveType(2) or re:IsActiveType(4))
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,0x200000,eg,1,0,0)
	Duel.SetOperationInfo(0,0x4000,nil,0,1-tp,5)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.DiscardDeck(1-tp,5,64) -- Mill 5
	end
end

-- Negate Summon Logic
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentChain()==0
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,0x200000,eg,#eg,0,0)
	Duel.SetOperationInfo(0,0x4000,nil,0,1-tp,5)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateSummon(eg)
	Duel.DiscardDeck(1-tp,5,64) -- Mill 5
end

-- GY Special Summon Logic
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 
		and Duel.IsExistingMatchingCard(s.spfilter,tp,16,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,16)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,4)
	if ft<=0 then return end
	if ft>2 then ft=2 end -- Up to 2
	Duel.Hint(3,tp,509)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,16,0,1,ft,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,1)
	end
end