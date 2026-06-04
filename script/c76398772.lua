local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 3 "Cyberdark" and/or "roid" monsters
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.matfilter,3,3)

	-- 1. Continuous Effect: Always treated as "Cyberdark Dragon"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_ADD_CODE)
	e1:SetValue(64184058) -- Card code for "Cyberdark Dragon"
	c:RegisterEffect(e1)

	-- 2. Continuous Effect: Cannot be targeted or destroyed by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetValue(aux.tgovval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetValue(aux.indoval)
	c:RegisterEffect(e3)

	-- 3. Quick Effect: Equip 1 "Cyberdark" or "roid" from GY during your turn
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_EQUIP)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.eqcon)
	e4:SetTarget(s.eqtg)
	e4:SetOperation(s.eqop)
	c:RegisterEffect(e4)

	-- 4. Continuous Effect: Gains 500 ATK for each equipped monster
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetValue(s.atkval)
	c:RegisterEffect(e5)

	-- 5. Continuous Effect: Gains an additional attack for each equipped monster
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_EXTRA_ATTACK)
	e6:SetValue(s.atkct)
	c:RegisterEffect(e6)

	-- 6. Ignition Effect: Destroy opponent's cards up to number of equipped monsters
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_DESTROY)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1,id+1000000)
	e7:SetTarget(s.destg)
	e7:SetOperation(s.desop)
	c:RegisterEffect(e7)

	-- 7. Continuous Effect: Substitute destruction by destroying 1 equipped monster instead
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e8:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e8:SetRange(LOCATION_MZONE)
	e8:SetValue(s.repval)
	c:RegisterEffect(e8)
end

s.listed_names={64184058} -- Cyberdark Dragon
s.listed_series={0x4093, 0x16} -- Cyberdark, roid

-- Fusion material helper filter
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x4093,fc,sumtype,tp) or c:IsSetCard(0x16,fc,sumtype,tp)
end

-- 3. Equip Logic
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end
function s.eqfilter(c)
	return (c:IsSetCard(0x4093) or c:IsSetCard(0x16)) and c:IsType(TYPE_MONSTER) and not c:IsForbidden()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
		if not Duel.Equip(tp,tc,c) then return end
		-- File dynamic equip handling limit logic safely
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(s.eqlimit)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end
function s.eqlimit(e,c)
	return c==e:GetOwner()
end

-- 4 & 5. Dynamic Stats Evaluation Logic
function s.atkfilter(c)
	return c:GetSequence()<5 -- Filters only actual cards residing natively inside the Spell/Trap Zone
end
function s.atkval(e,c)
	return c:GetEquipGroup():FilterCount(s.atkfilter,nil)*500
end
function s.atkct(e,c)
	return e:GetHandler():GetEquipGroup():FilterCount(s.atkfilter,nil)
end

-- 6. Targeted Card Wipe Logic
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local count=e:GetHandler():GetEquipGroup():FilterCount(s.atkfilter,nil)
	if chk==0 then return count>0 and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local count=c:GetEquipGroup():FilterCount(s.atkfilter,nil)
	if count<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,count,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- 7. Substitute Destruction Replacement Logic
function s.repval(e,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetEquipGroup():Filter(s.atkfilter,nil)
	if #g>0 and (r&REASON_DESTROY)~=0 then
		Duel.Hint(HINT_SELECTMSG,e:GetHandlerPlayer(),HINTMSG_DESTROY)
		local sg=g:Select(e:GetHandlerPlayer(),1,1,nil)
		Duel.Destroy(sg,REASON_EFFECT)
		return true
	end
	return false
end