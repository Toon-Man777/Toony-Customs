local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: 2 Level 4 "Toy" Monsters
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x1a4),4,2)
	c:EnableReviveLimit()

	-- Effect 1: When this card attacks, destroy 1 Set card on your field to gain 500 ATK
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.atk_des_tg)
	e1:SetOperation(s.atk_des_op)
	c:RegisterEffect(e1)

	-- Effect 2: When this card leaves the field, you can detach 1 material instead
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.leave_replace_tg)
	c:RegisterEffect(e2)
	-- Handles non-destruction "leaves field" events (send to GY, banish, bounce, etc.)
	local e2b=Effect.CreateEffect(c)
	e2b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2b:SetCode(EFFECT_SEND_REPLACE)
	e2b:SetRange(LOCATION_MZONE)
	e2b:SetTarget(s.leave_replace_tg2)
	e2b:SetOperation(s.leave_replace_op2)
	c:RegisterEffect(e2b)

	-- Effect 3: When this card is destroyed, set this card in your Spell/Trap zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.set_self_cond) -- Only triggers if destroyed while acting as a monster/hand element
	e3:SetTarget(s.set_self_tg)
	e3:SetOperation(s.set_self_op)
	c:RegisterEffect(e3)

	-- Effect 4: FIXED - Special Summon itself when destroyed while in the Spell/Trap zone
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_GRAVE+LOCATION_REMOVED)
	e4:SetCountLimit(1,id+300)
	e4:SetCondition(s.sp_cond_fixed)
	e4:SetTarget(s.sp_tg_fixed)
	e4:SetOperation(s.sp_op_fixed)
	c:RegisterEffect(e4)

	-- Effect 5: While you control "Toy Box", this card cannot be destroyed by card effects
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.prot_cond)
	e5:SetValue(1)
	c:RegisterEffect(e5)
end

s.listed_names={24878656} -- Toy Box Card ID

-- Effect 1 Handlers: Attack and destroy face-down card
function s.atk_des_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFacedown,tp,LOCATION_ONFIELD,0,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFacedown,tp,LOCATION_ONFIELD,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.atk_des_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,Card.IsFacedown,tp,LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 then
		-- Spoons an altered player index parameter (1-tp) into the engine's reason context 
		-- This tricks the engine into reading the game state as "Your Opponent destroyed this card"
		if Duel.Destroy(g,REASON_EFFECT,LOCATION_GRAVE,1-tp)~=0 and c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(500)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end

-- Effect 2 Handlers: Material detachment replacement system
function s.leave_replace_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsReason(REASON_REPLACE) and c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT) end
	if Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,3)) then
		c:RemoveOverlayCard(tp,1,1,REASON_EFFECT)
		return true
	end
	return false
end
function s.leave_replace_tg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Intercepts any leave-field movement command
	if chk==0 then return c:GetDestination()~=LOCATION_MZONE and c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT) end
	return Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,3))
end
function s.leave_replace_op2(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_EFFECT)
end

-- Effect 3 Handlers: Backrow placement on pop
function s.set_self_cond(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsPreviousLocation(LOCATION_SZONE)
end
function s.set_self_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.set_self_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
		local e1=Effect.CreateEffect(c)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(TYPE_SPELL)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
		c:RegisterEffect(e1)
	end
end

-- Effect 4 Handlers: Global validation backrow tracker
function s.sp_cond_fixed(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return eg:IsContains(c) and c:IsPreviousLocation(LOCATION_SZONE)
end
function s.sp_tg_fixed(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.sp_op_fixed(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Effect 5 Handlers: Toy Box Protection
function s.toybox_filter(c)
	return c:IsFaceup() and c:IsCode(24878656)
end
function s.prot_cond(e)
	return Duel.IsExistingMatchingCard(s.toybox_filter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end