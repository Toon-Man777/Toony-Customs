local s,id=GetID()
function s.initial_effect(c)
	-- Special Summon from hand + Mill 2
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(0x1+0x4000) -- CATEGORY_SPECIAL_SUMMON+CATEGORY_DECKDES
	e1:SetType(4) -- EFFECT_TYPE_IGNITION
	e1:SetRange(2) -- LOCATION_HAND
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Treated as a Tuner
	local e2=Effect.CreateEffect(c)
	e2:SetType(1) -- EFFECT_TYPE_SINGLE
	e2:SetProperty(0x80+0x40000) -- EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE
	e2:SetCode(4003) -- EFFECT_TYPE_TUNER
	c:RegisterEffect(e2)

	-- Level adjustment (Once per turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(4) -- EFFECT_TYPE_IGNITION
	e3:SetRange(4) -- LOCATION_MZONE
	e3:SetCountLimit(1)
	e3:SetOperation(s.lvop)
	c:RegisterEffect(e3)

	-- Thrice per turn: Summon "Iron Chain" when opponent mills
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(0x1)
	e4:SetType(160) -- EFFECT_TYPE_QUICK_O
	e4:SetCode(4101) -- EVENT_TO_GRAVE
	e4:SetRange(4) -- LOCATION_MZONE
	e4:SetCountLimit(3)
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

-- Special Summon from hand logic
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,0x1,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,0x4000,nil,0,1-tp,2)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,1)>0 then
		Duel.DiscardDeck(1-tp,2,64) -- REASON_EFFECT
	end
end

-- Increase/Decrease Level logic
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4)) -- Increase or Decrease
		local val = (op==0) and 1 or -1
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(12) -- EFFECT_UPDATE_LEVEL
		e1:SetValue(val)
		e1:SetReset(0x1fe0000) -- RESET_EVENT+RESETS_STANDARD
		c:RegisterEffect(e1)
	end
end

-- Reactive Summon logic
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	-- Checks if cards were sent from opponent's DECK to GY
	return eg:IsExists(function(tc) return tc:IsPreviousLocation(1) and tc:GetControler()==1-tp end,1,nil)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,8) -- POS_FACEUP_DEFENSE
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,1+16,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,1+16)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,4)<=0 then return end
	Duel.Hint(3,tp,509) -- HINTMSG_SPSUMMON
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,1+16,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,8)
	end
end