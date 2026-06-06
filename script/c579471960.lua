local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Negate an opponent's card or effect activation
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- Effect 2: Set itself from the GY by destroying 1 Fairy monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id) -- Hard once per turn on the activate/set effect
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

s.listed_names={27288416} -- "Mokey Mokey"
s.listed_series={0x184}   -- Mokey Mokey archetype

-- 1. Negation Effect Logic
function s.cfilter(c)
	-- Checks if you control a face-up "Mokey Mokey" monster (or named as such)
	return c:IsFaceup() and (c:IsCode(27288416) or c:IsSetCard(0x184)) and c:IsMonster()
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- Must control a "Mokey Mokey" monster, and the opponent must activate something negatable
	return rp==1-tp and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- 2. GY Recurring Logic
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	-- Cannot be activated during the turn it was sent to the GY
	return e:GetHandler():GetTurnID()~=Duel.GetTurnCount()
end
function s.desfilter(c)
	-- Targets a Fairy monster on your field to destroy
	return c:IsRace(RACE_FAIRY) and (c:IsFaceup() or c:IsLocation(LOCATION_MZONE))
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_MZONE,0,1,nil)
		and c:IsCanBePlacedOnField(true) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)~=0 and c:IsRelateToEngine() then
		-- Sets the trap directly to your field
		if Duel.SSet(tp,c)~=0 then
			-- Applies the standard restriction: banish it when it leaves the field
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(3300)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
			e1:SetValue(LOCATION_REMOVED)
			e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
			c:RegisterEffect(e1)
		end
	end
end