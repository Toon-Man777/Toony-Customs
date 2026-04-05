-- Odd-Eyes Performapal Magician of Timegazing
local s,id=GetID()
function s.initial_effect(c)
	-- Pendulum Summon
	Pendulum.AddProcedure(c)
	
	-- PENDULUM EFFECTS
	-- Battle Protection: Opponent cannot activate Trap cards or monster effects from GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(0,1)
	e1:SetCondition(s.actcon)
	e1:SetValue(s.actlimit)
	c:RegisterEffect(e1)

	-- LP Protection: Opponent cannot activate effects in response to Pendulum Summon
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_CHHAIN)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_PZONE)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.lpcon)
	e2:SetValue(s.chainlimit)
	c:RegisterEffect(e2)

	-- MONSTER EFFECTS
	-- First destruction protection for themed monsters each turn
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.indtg)
	e3:SetValue(s.indval)
	c:RegisterEffect(e3)

	-- Quick Effect: Return P-Zone card to hand to negate and banish
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_TOHAND+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_BECOME_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.negcon)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)

	-- Place in P-Zone if destroyed
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_DESTROYED)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetTarget(s.pentg)
	e5:SetOperation(s.penop)
	c:RegisterEffect(e5)
end

-- Helper: Check for Magician, Odd-Eyes, or Performapal
function s.is_themed(c)
	return c:IsSetCard(0x98) or c:IsSetCard(0x99) or c:IsSetCard(0x9f)
end

-- Pendulum Battle Lock logic
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return (a and a:IsControler(tp) and s.is_themed(a)) or (d and d:IsControler(tp) and s.is_themed(d))
end
function s.actlimit(e,re,tp)
	return re:IsActiveType(TYPE_TRAP) or re:GetActivateLocation()==LOCATION_GRAVE
end

-- LP Response Lock logic
function s.lpcon(e)
	return Duel.GetLP(e:GetHandlerPlayer()) > Duel.GetLP(1-e:GetHandlerPlayer())
end
function s.chainlimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_SPSUMMON) and re:GetHandler():IsType(TYPE_PENDULUM)
end

-- Monster Protection logic
function s.indtg(e,c)
	return s.is_themed(c) and c:IsType(TYPE_PENDULUM)
end
function s.indval(e,re,r,rp)
	if (r&REASON_EFFECT)~=0 then return 1 end
	return 0
end

-- Negation logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.indtg,1,nil) -- Target must be a themed Pendulum
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.is_themed,tp,LOCATION_PZONE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_PZONE)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectMatchingCard(tp,s.is_themed,tp,LOCATION_PZONE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		if Duel.NegateEffect(ev) and re:GetHandler():IsRelateToEffect(re) then
			Duel.Remove(re:GetHandler(),POS_FACEUP,REASON_EFFECT)
		end
	end
end

-- P-Zone Move logic
function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1) end
end
function s.penop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.MoveToField(e:GetHandler(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
end