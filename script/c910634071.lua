local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon: 1 "Iron Chain" tuner + 1+ non-tuner monsters
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x25),1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	-- On Synchro Summon: Banish from GY to Special Summon "Iron Chain" from Deck/Extra
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(0x1+0x8) -- CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE
	e1:SetType(1+0x40) -- EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O
	e1:SetCode(1011) -- EVENT_SPSUMMON_SUCCESS
	e1:SetProperty(0x10000) -- EFFECT_FLAG_DELAY
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- When opponent summons: Send top card of opponent's deck to GY
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x4000) -- CATEGORY_DECKDES
	e2:SetType(16+0x40) -- EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F
	e2:SetRange(4) -- LOCATION_MZONE
	e2:SetCode(1012) -- EVENT_SUMMON_SUCCESS
	e2:SetOperation(s.millop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(1011) -- EVENT_SPSUMMON_SUCCESS
	c:RegisterEffect(e3)

	-- Banish this card from GY: Special Summon 1 "Iron Chain" from GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(0x1)
	e4:SetType(4) -- EFFECT_TYPE_IGNITION
	e4:SetRange(16) -- LOCATION_GRAVE
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

-- On-Summon Banish/Summon Logic
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(0x10) -- SUMMON_TYPE_SYNCHRO
end
function s.spfilter1(c,e,tp)
	return c:IsSetCard(0x25) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,16,0,1,nil)
		and Duel.GetLocationCount(tp,4)>0 end
	Duel.SetOperationInfo(0,0x8,nil,1,tp,16)
	Duel.SetOperationInfo(0,0x1,nil,1,tp,1+0x40) -- Deck or Extra Deck
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,4)
	if ft<=0 then return end
	local bg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,16,0,nil)
	if #bg==0 then return end
	local max_ct = math.min(ft,#bg)
	Duel.Hint(3,tp,505) -- HINTMSG_REMOVE
	local r_g = bg:Select(tp,1,max_ct,nil)
	local ct = Duel.Remove(r_g,0,64)
	if ct>0 then
		Duel.Hint(3,tp,509) -- HINTMSG_SPSUMMON
		local s_g = Duel.SelectMatchingCard(tp,s.spfilter1,tp,1+64,0,ct,ct,nil,e,tp)
		if #s_g>0 then
			Duel.SpecialSummon(s_g,0,tp,tp,false,false,1)
		end
	end
end

-- Milling Logic
function s.millop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(Card.IsControler,1,nil,1-tp) then
		Duel.DiscardDeck(1-tp,1,64)
	end
end

-- GY Revive Logic
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,4)>0
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,16,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,16)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,4)<=0 then return end
	Duel.Hint(3,tp,509)
	local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,16,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,1)
	end
end