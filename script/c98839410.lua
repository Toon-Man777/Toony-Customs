local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon: 2+ "R.B." Monsters
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x1ca),2,99)

	-- 1. Continuous: Gains 500 ATK for each "R.B." monster pointed to
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Discard 1 "R.B." to negate 1 opponent's card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(3,id) -- Thrice per turn shared check
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- 3. Ignition Effect: Pay 1000 LP to banish 1 card on the field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(3,id) -- Thrice per turn shared check
	e3:SetCost(s.banishcost)
	e3:SetTarget(s.banishtg)
	e3:SetOperation(s.banishop)
	c:RegisterEffect(e3)

	-- 4. Ignition Effect: Banish 2 Spells/Traps from GY to buff ATK & Attack twice
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(3,id) -- Thrice per turn shared check
	e4:SetCost(s.buffcost)
	e4:SetTarget(s.bufftg)
	e4:SetOperation(s.buffop)
	c:RegisterEffect(e4)

	-- 5. Continuous: Opponent takes half the battle damage involving this card
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(0,1)
	e5:SetValue(aux.ChangeBattleDamage(1,HALF_DAMAGE))
	c:RegisterEffect(e5)

	-- 6. Trigger Effect: End Phase move self and add 1 "R.B." monster from GY
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,3))
	e6:SetCategory(CATEGORY_TOHAND)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(3,id) -- Thrice per turn shared check
	e6:SetCondition(s.mvcon)
	e6:SetTarget(s.mvtg)
	e6:SetOperation(s.mvop)
	c:RegisterEffect(e6)

	-- 7. Continuous Zone Lock: Opponent's unoccupied zones pointed to cannot be used
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCode(EFFECT_DISABLE_FIELD)
	e7:SetValue(s.zonelockval)
	c:RegisterEffect(e7)

	-- 8. Continuous: Cannot be destroyed by opponent's card effects while pointing to "R.B."
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e8:SetCondition(s.indcon)
	e8:SetValue(aux.indoval)
	c:RegisterEffect(e8)

	-- 9. Trigger Effect: When an opponent's card is banished, lock an unused zone
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,4))
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e9:SetCode(EVENT_REMOVE)
	e9:SetRange(LOCATION_MZONE)
	e9:SetProperty(EFFECT_FLAG_DELAY)
	e9:SetCondition(s.lockcon)
	e9:SetTarget(s.locktg)
	e9:SetOperation(s.lockop)
	c:RegisterEffect(e9)
end

-- 1. Passive ATK Pointing Calculator
function s.atkval(e,c)
	return c:GetLinkedGroup():FilterCount(Card.IsSetCard,nil,0x1ca)*500
end

-- 2. Hand-Discard Negation Engine
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainDisablable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_HAND,0,1,nil,0x1ca) end
	Duel.DiscardHand(tp,Card.IsSetCard,1,1,REASON_COST+REASON_DISCARD,nil,0x1ca)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISABLE)
	local g=Duel.SelectMatchingCard(tp,Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		local tc=g:GetFirst()
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
end

-- 3. Banish Target Effect
function s.banishcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.banishtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,LOCATION_ONFIELD)
end
function s.banishop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- 4. Unoccupied Zone Math Scaler
function s.buffcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsSpellTrap,tp,LOCATION_GRAVE,0,2,nil) and Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,tp,LOCATION_GRAVE,0,2,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsSpellTrap,tp,LOCATION_GRAVE,0,2,2,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.bufftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.buffop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFaceup() == false then return end

	-- Calculate every single vacant structural zone on the field (Monster Zones + Spell/Trap Zones)
	local free_zones = 0
	for p=0,1 do
		-- Loop over standard Monster columns (0-4) + Spell zones (0-4)
		for i=0,4 do
			if Duel.CheckLocation(p,LOCATION_MZONE,i) then free_zones = free_zones + 1 end
			if Duel.CheckLocation(p,LOCATION_SZONE,i) then free_zones = free_zones + 1 end
		end
		-- Check extra monster zones safely
		if Duel.CheckLocation(p,LOCATION_MZONE,5) then free_zones = free_zones + 1 end
		if Duel.CheckLocation(p,LOCATION_MZONE,6) then free_zones = free_zones + 1 end
		-- Check Field Spell slot (Zone indices 5)
		if Duel.CheckLocation(p,LOCATION_SZONE,5) then free_zones = free_zones + 1 end
	end

	if free_zones > 0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(free_zones * 500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end

	-- Double Attack Parameter grant
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetValue(1)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e2)
end

-- 6. End Phase Move and Recycle
function s.mvcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end
function s.mvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(Card.IsSetCard),tp,LOCATION_GRAVE,0,1,nil,0x1ca) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.mvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1-tp) or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOZONE)
	local zone=Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0)
	-- Convert the field selection bitmask to a logical sequences slot index
	local seq=math.log(zone,2)
	
	if Duel.MoveSequence(c,seq) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.mfilter),tp,LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end
function s.mfilter(c)
	return c:IsSetCard(0x1ca) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

-- 7. Fixed Pointing Arrow Zone Locker
function s.zonelockval(e)
	local c=e:GetHandler()
	local tp=e:GetHandlerPlayer()
	-- Get zones pointed to by this card relative to the opponent's field layout mapping
	local zones=c:GetLinkedZone(1-tp) & 0x1f
	-- Shift bits to correctly overlay onto the opponent's field perspective index
	return zones << 16
end

-- 8. Protection Condition
function s.indcon(e)
	return e:GetHandler():GetLinkedGroup():IsExists(Card.IsSetCard,1,nil,0x1ca)
end

-- 9. Trigger-Based On-Field Zone Locker
function s.lockfilter(c,tp)
	return c:IsControler(1-tp) and c:IsLocation(LOCATION_REMOVED)
end
function s.lockcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.lockfilter,1,nil,tp) and not Duel. someType == SUMMON_TYPE_DAMAGE
end
function s.locktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.lockop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- Open a target UI allowing the player to select any unused monster or S/T zone on either field
	local flag=Duel.SelectDisableField(tp,1,LOCATION_ONFIELD,LOCATION_ONFIELD,0)
	
	-- Apply a permanent field-lock effect tied to this card being face-up
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(flag)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
end