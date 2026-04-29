local s,id=GetID()
function s.initial_effect(c)
	-- Activate: SS Level 4-
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x1):SetType(0x10000):SetCode(0):SetOperation(s.activate)
	c:RegisterEffect(e1)
	-- SS Limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(16):SetCode(460):SetRange(8):SetTargetRange(0,1)
	e2:SetCondition(function(e) return Duel.IsExistingMatchingCard(Card.IsSetCard,e:GetHandlerPlayer(),4,0,2,nil,0x25) end)
	e2:SetTarget(function(e,c,sump,sumtype,sumpos,targetp,se) return se and se:IsHasCategory(0x1) and Duel.GetLocationCount(targetp,4)>1 end)
	c:RegisterEffect(e2)
	-- 800 ATK/DEF Boost
	local e3=Effect.CreateEffect(c)
	e3:SetType(16):SetCode(100):SetRange(8):SetTargetRange(4,0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x25)):SetValue(800)
	c:RegisterEffect(e3)
	local e4=e3:Clone():SetCode(101)
	c:RegisterEffect(e4)
	-- Banish instead of GY
	local e5=Effect.CreateEffect(c)
	e5:SetType(16):SetCode(133):SetRange(8):SetCountLimit(1)
	e5:SetCondition(function(e,tp,eg,ep,ev,re) return re and re:GetHandler():IsSetCard(0x25) end)
	e5:SetOperation(function(e,tp,eg) Duel.Banish(eg,0,64) end)
	c:RegisterEffect(e5)
end
function s.activate(e,tp)
	local g=Duel.SelectMatchingCard(tp,function(c,e,tp) return c:IsSetCard(0x25) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,1+16,0,1,1,nil,e,tp)
	if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,1) end
end