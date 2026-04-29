local s,id=GetID()
function s.initial_effect(c)
	-- 1. Special Summon from hand + Mill 2
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(0x1+0x4000) -- CATEGORY_SPECIAL_SUMMON + CATEGORY_DECKDES
	e1:SetType(4) -- EFFECT_TYPE_IGNITION
	e1:SetRange(2) -- LOCATION_HAND
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Can be treated as a non-tuner for "Iron Chain" Synchro
	local e2=Effect.CreateEffect(c)
	e2:SetType(1) -- EFFECT_TYPE_SINGLE
	e2:SetProperty(0x400) -- EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE
	e2:SetCode(4005) -- EFFECT_NONTUNER_S_MATERIAL
	e2:SetValue(function(e,sc) return sc:IsSetCard(0x25) end)
	c:RegisterEffect(e2)

	-- 3. Level +/- 1 (Once per turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(4)
	e3:SetRange(4) -- LOCATION_MZONE
	e3:SetCountLimit(1)
	e3:SetOperation(s.lvop)
	c:RegisterEffect(e3)

	-- 4. Quick Effect: Mill Trigger -> Special Summon
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(0x1)
	e4:SetType(16+0x40) -- EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O
	e4:SetProperty(0x10000) -- EFFECT_FLAG_DELAY
	e4:SetCode(1001) -- EVENT_TO_GRAVE
	e4:SetRange(4)
	e4:SetCountLimit(1)
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

-- Hand SS + Mill Logic
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,0x1,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,0x4000,nil,0,1-tp,2)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,1)>0 then
		Duel.DiscardDeck(1-tp,2,64)
	end
end

-- Level Mod Logic
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local op=Duel.SelectOption(tp,1016,1017)
		local val=(op==0) and 1 or -1
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(12) -- EFFECT_UPDATE_LEVEL
		e1:SetValue(val)
		e1:SetReset(0x1fe0000)
		c:RegisterEffect(e1)
	end
end

-- Reactive SS Logic
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	-- When a card from opponent's deck is sent to GY
	return eg:IsExists(function(c) return c:IsControler(1-tp) and c:IsPreviousLocation(1) end,1,nil)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0 and Duel.IsExistingMatchingCard(function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,2+16,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,2+16)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,509)
	local g=Duel.SelectMatchingCard(tp,function(c,e,tp) return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,2+16,0,1,1,nil,e,tp)
	if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,1) end
end