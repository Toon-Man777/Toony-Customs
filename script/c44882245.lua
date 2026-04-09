local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon: 1 Tuner + 1 non-tuner Spellcaster monster
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(Card.IsRace,RACE_SPELLCASTER),1,1)
	c:EnableReviveSelection()

	-- 1. Gain 300 ATK/DEF for each Spellcaster in GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	-- 2. Opponent's turn: Banish and Destroy (Once per turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE+CATEGORY_DESTROY+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)

	-- 3. Discard to Search (Once per turn)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(s.thcost)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

s.listed_series={0x20a2} -- Magician Girl
s.listed_names={38033121} -- Dark Magician Girl

-- ATK/DEF gain logic
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(Card.IsRace,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil,RACE_SPELLCASTER)*300
end

-- Destruction logic
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x20a2),tp,LOCATION_MZONE,0,1,nil)
end
function s.desfilter1(c)
	return c:IsRace(RACE_SPELLCASTER) and c:IsAbleToRemove()
end
function s.desfilter2(c)
	return c:IsSpell() and c:IsAbleToRemove()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter1,tp,LOCATION_GRAVE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.desfilter2,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,2,tp,LOCATION_GRAVE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=Duel.SelectMatchingCard(tp,s.desfilter1,tp,LOCATION_GRAVE,0,1,1,nil)
	local g2=Duel.SelectMatchingCard(tp,s.desfilter2,tp,LOCATION_GRAVE,0,1,1,nil)
	g1:Merge(g2)
	if #g1==2 and Duel.Remove(g1,POS_FACEUP,REASON_EFFECT)>0 then
		local tc=g1:Filter(Card.IsType,nil,TYPE_MONSTER):GetFirst()
		local ct=math.floor(tc:GetLevel()/2)
		local dg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
		if ct>0 and #dg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local des=dg:Select(tp,1,ct,nil)
			Duel.Destroy(des,REASON_EFFECT)
		end
		-- Shuffle during End Phase
		if c:IsRelateToEffect(e) then
			c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PHASE+PHASE_END)
			e1:SetCountLimit(1)
			e1:SetCondition(s.retcon)
			e1:SetOperation(s.retop)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)~=0
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end

-- Search logic
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.thfilter(c)
	return (c:IsSetCard(0x20a2) or c:ListsCode(38033121)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end