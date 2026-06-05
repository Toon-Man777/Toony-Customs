local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Negate an opponent's card or effect activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- Effect 2: While in GY, destroy 1 Fairy monster to Set this card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

s.listed_names={27288416} -- Mokey Mokey

-- 1. Negation Effect Handlers
function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(27288416) -- Controls a "Mokey Mokey" monster
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) and rc:IsMonster() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		if rc:IsRelateToEffect(re) and rc:IsMonster() then
			Duel.Destroy(eg,REASON_EFFECT)
		end
	end
end

-- 2. GY Self-Set Handlers
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetTurnID()~=Duel.GetTurnCount() -- Except the turn it was sent to the GY
end
function s.desfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_FAIRY) -- 1 Fairy monster on your field
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSSetable()
		and Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_MZONE,0,1,nil) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)~=0 and c:IsRelateToEffect(e) then
		if Duel.SSet(tp,c)~=0 then
			-- Banish this card when it leaves the field
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(3300)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(LOCATION_REMOVED)
			e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
			c:RegisterEffect(e1)
		end
	end
end