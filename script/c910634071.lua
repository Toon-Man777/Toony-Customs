local s,id=GetID()
function s.initial_effect(c)
	-- Synchro: 1 "Iron Chain" tuner + 1+ non-tuners
	Synchro.AddProcedure(c,function(c) return c:IsSetCard(0x25) end,1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()
	-- On Synchro SS
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x1+0x8)
	e1:SetType(1+0x40)
	e1:SetCode(1011)
	e1:SetProperty(0x10000)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(0x10) end)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)
	-- Mill on Opponent Summon
	local e2=Effect.CreateEffect(c)
	e2:SetType(16+0x40)
	e2:SetRange(4)
	e2:SetCode(1011)
	e2:SetOperation(function(e,tp,eg) if eg:IsExists(Card.IsControler,1,nil,1-tp) then Duel.DiscardDeck(1-tp,1,64) end end)
	c:RegisterEffect(e2)
	-- Banish from GY to revive
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(0x1)
	e3:SetType(4)
	e3:SetRange(16)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,16,0,1,nil) end
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local bg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,16,0,nil)
	if #bg==0 then return end
	local r_g=bg:Select(tp,1,Duel.GetLocationCount(tp,4),nil)
	local ct=Duel.Remove(r_g,0,64)
	if ct>0 then
		local g=Duel.SelectMatchingCard(tp,function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,1+64,0,ct,ct,nil,e,tp)
		Duel.SpecialSummon(g,0,tp,tp,false,false,1)
	end
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 and Duel.IsExistingMatchingCard(function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,16,0,1,nil,e,tp) end
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,16,0,1,1,nil,e,tp)
	if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,1) end
end