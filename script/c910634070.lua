local s,id=GetID()
function s.initial_effect(c)
	-- 1. Special Summon from hand if you control "Iron Chain"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(0x1) -- CATEGORY_SPECIAL_SUMMON
	e1:SetType(4) -- EFFECT_TYPE_IGNITION
	e1:SetRange(2) -- LOCATION_HAND
	e1:SetCountLimit(1,id) -- HOPT 1
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Level +/- 1 (Once per turn)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(4)
	e2:SetRange(4) -- LOCATION_MZONE
	e2:SetCountLimit(1,id+1) -- HOPT 2
	e2:SetOperation(s.lvop)
	c:RegisterEffect(e2)

	-- 3. GY Search: Add 1 "Iron Chain" monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(0x2+0x4) -- CATEGORY_SEARCH + CATEGORY_TOHAND
	e3:SetType(1+0x40) -- EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O
	e3:SetProperty(0x10000) -- EFFECT_FLAG_DELAY
	e3:SetCode(1001) -- EVENT_TO_GRAVE
	e3:SetCountLimit(1,id+2) -- HOPT 3
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

-- Special Summon Logic
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x25) and c:IsFaceup() end,tp,4,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,0x1,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,1)
	end
end

-- Level Adjustment Logic
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local op=Duel.SelectOption(tp,1016,1017) -- 1016: Increase, 1017: Decrease
		local val=(op==0) and 1 or -1
		local e1=Effect.CreateEffect(c)
		e1:SetType(1) -- EFFECT_TYPE_SINGLE
		e1:SetCode(12) -- EFFECT_UPDATE_LEVEL
		e1:SetValue(val)
		e1:SetReset(0x1fe0000)
		c:RegisterEffect(e1)
	end
end

-- Search Logic
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x25) and c:IsType(1) and c:IsAbleToHand() end,tp,1,0,1,nil) end
	Duel.SetOperationInfo(0,0x2,nil,1,tp,1)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,511)
	local g=Duel.SelectMatchingCard(tp,function(c) return c:IsSetCard(0x25) and c:IsType(1) and c:IsAbleToHand() end,tp,1,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,64)
		Duel.ConfirmCards(1-tp,g)
	end
end