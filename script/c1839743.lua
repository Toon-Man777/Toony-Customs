--Fierce Welcome Labrynth
local s,id=GetID()
function s.initial_effect(c)

	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--GY effect: allow trap activation same turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)

end

--Condition to activate the turn it was set
function s.cfilter(c)
	return c:IsSetCard(0x17f)
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE+LOCATION_MZONE+LOCATION_HAND,0,1,nil)
end

--Target monster
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,0,0)
end

--Send monster then set trap
function s.trapfilter(c)
	return c:IsNormalTrap() and c:IsSSetable()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end

	local sg=Duel.SelectMatchingCard(tp,s.trapfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	local sc=sg:GetFirst()
	if sc then
		Duel.SSet(tp,sc)
	end
end

--GY effect
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if re:IsActiveType(TYPE_TRAP) and rc:IsNormalTrap() then
		local c=e:GetHandler()
		if c:IsAbleToRemove() then
			Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetTargetRange(LOCATION_SZONE,0)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end