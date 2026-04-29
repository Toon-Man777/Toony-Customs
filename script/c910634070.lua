local s,id=GetID()
function s.initial_effect(c)
	-- Hand SS + Mill 2
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x1+0x4000) 
	e1:SetType(4) 
	e1:SetRange(2) 
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- Always Tuner
	local e2=Effect.CreateEffect(c)
	e2:SetType(1)
	e2:SetCode(4003) 
	c:RegisterEffect(e2)
	-- Level +/- 1
	local e3=Effect.CreateEffect(c)
	e3:SetType(4)
	e3:SetRange(4)
	e3:SetCountLimit(1)
	e3:SetOperation(s.lvop)
	c:RegisterEffect(e3)
	-- Reactive SS (Thrice per turn)
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(0x1)
	e4:SetType(160)
	e4:SetCode(4101)
	e4:SetRange(4)
	e4:SetCountLimit(3)
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,0x1,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,1)>0 then
		Duel.DiscardDeck(1-tp,2,64)
	end
end
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local op=Duel.SelectOption(tp,1016,1017)
		local val=(op==0) and 1 or -1
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(12)
		e1:SetValue(val)
		e1:SetReset(0x1fe0000)
		c:RegisterEffect(e1)
	end
end
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(tc) return tc:IsPreviousLocation(1) and tc:GetControler()==1-tp end,1,nil)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 and Duel.IsExistingMatchingCard(function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,8) end,tp,1+16,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,1+16)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,509)
	local g=Duel.SelectMatchingCard(tp,function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,8) end,tp,1+16,0,1,1,nil,e,tp)
	if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,8) end
end