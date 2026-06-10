local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: 2 Level 4 "Toy" Monsters
	Xyz.AddProcedure(c,s.xyzfilter,4,2)
	c:EnableReviveLimit()

	-- Effect 1: When this card attacks, destroy 1 Set card on your field to gain 500 ATK
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.des_target)
	e1:SetOperation(s.des_operation)
	c:RegisterEffect(e1)

	-- Effect 2: When this card leaves the field, detach 1 material instead
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_SEND_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.rep_target)
	e2:SetData(c)
	c:RegisterEffect(e2)

	-- Effect 3: When this card is destroyed, set it in your Spell/Trap Zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.set_self_tg)
	e3:SetOperation(s.set_self_op)
	c:RegisterEffect(e3)

	-- Effect 4: If destroyed while in the Spell/Trap Zone, Special Summon it
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.sp_cond)
	e4:SetTarget(s.sp_tg)
	e4:SetOperation(s.sp_op)
	c:RegisterEffect(e4)

	-- Effect 5: Cannot be destroyed by card effects while you control "Toy Box"
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.prot_cond)
	e5:SetValue(1)
	c:RegisterEffect(e5)
end

s.listed_names={24878656} -- UPDATED: Toy Box Card ID

function s.xyzfilter(c,xyz,sumtype,tp)
	return c:IsSetCard(0x1a0) or string.find(c:GetOriginalName() or "","Toy")~=nil
end

-- EFFECT 1
function s.des_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(Card.IsFacedown,tp,LOCATION_ONFIELD,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.des_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,Card.IsFacedown,tp,LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)~=0 and c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end

-- EFFECT 2
function s.rep_target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsReason(REASON_DESTROY+REASON_RELEASE+REASON_BANISH+REASON_TOGRAVE+REASON_TOHAND+REASON_TODECK) 
		and c:GetOverlayCount()>0 end
	if Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,3)) then
		c:RemoveOverlayCard(tp,1,1,REASON_EFFECT)
		return true
	end
	return false
end

-- EFFECT 3
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

-- EFFECT 4
function s.sp_cond(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_SZONE)
end
function s.sp_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.sp_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- EFFECT 5 (Protection)
function s.toybox_filter(c)
	return c:IsFaceup() and c:IsCode(24878656) -- UPDATED: Toy Box ID
end
function s.prot_cond(e)
	return Duel.IsExistingMatchingCard(s.toybox_filter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end