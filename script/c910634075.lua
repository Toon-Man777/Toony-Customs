local s,id=GetID()
function s.initial_effect(c)
	-- Negate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x200000+0x4000):SetType(0x10000):SetCode(4101)
	e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return rp~=tp and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,4,0,2,nil,0x25) and Duel.IsChainNegatable(ev) end)
	e1:SetOperation(function(e,tp,eg,ep,ev) if Duel.NegateActivation(ev) then Duel.DiscardDeck(1-tp,5,64) end end)
	c:RegisterEffect(e1)
	-- Banish from GY to SS
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x1):SetType(4):SetRange(16):SetCountLimit(1,id):SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,1+16,0,nil,e,tp)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 and g:CheckWithSumEqual(Card.GetLevel,6,1,2) end
end
function s.spop(e,tp)
	local g=Duel.GetMatchingGroup(function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,1+16,0,nil,e,tp)
	local sg=g:SelectWithSumEqual(tp,Card.GetLevel,6,1,2)
	if #sg>0 then Duel.SpecialSummon(sg,0,tp,tp,false,false,1) end
end