local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon materials: 3 Level 8 "Galaxy-Eyes" monsters
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x107b),8,3)
	c:EnableReviveLimit()

	-- 1. Continuous Effect: Can only control 1
	c:SetUniqueOnField(1,0,id)

	-- 2. Continuous Effect: Unaffected by opponent's card effects while having "Galaxy-Eyes Photon Dragon"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetCondition(s.immcon)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)

	-- 3. Trigger Effect: When Xyz Summoned, search 1 "Galaxy"/"Photon"/"Cipher" and Special Summon 1 LIGHT monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- 4. Ignition Effect: Detach 1 to negate all other monsters and make their names "Galaxy-Eyes"
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DISABLE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1000000)
	e3:SetCost(Xyz.CutCost(1))
	e3:SetTarget(s.distg)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)

	-- 5. Trigger Effect: During the End Phase, take control of 1 Xyz monster and attach the rest as materials
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_CONTROL)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+2000000)
	e4:SetTarget(s.ctltg)
	e4:SetOperation(s.ctlop)
	c:RegisterEffect(e4)

	-- 6. Trigger Effect: During the Standby Phase, banish Xyz monsters from GY to gain ATK
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+3000000)
	e5:SetCondition(s.atkcon)
	e5:SetTarget(s.atktg)
	e5:SetOperation(s.atkop)
	c:RegisterEffect(e5)
end

s.listed_names={93717133} -- Galaxy-Eyes Photon Dragon
s.listed_series={0x7b, 0x55, 0xe5} -- Galaxy, Photon, Cipher

-- 2. Immunity Logic
function s.immcon(e)
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,93717133)
end
function s.efilter(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- 3. Search & Special Summon Logic
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.thfilter(c)
	return (c:IsSetCard(0x7b) or c:IsSetCard(0x55) or c:IsSetCard(0xe5)) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
			and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
			if #sg>0 then
				Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
			end
		end
	end
end

-- 4. Global Board Negation & Name Manipulation Logic
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.NOT(Xyz.NameconFilter),tp,LOCATION_MZONE,LOCATION_MZONE,1,e:GetHandler()) end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,c)
	for tc in aux.Next(g) do
		-- Negate Effects
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY+RESET_OPPO_TURN)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY+RESET_OPPO_TURN)
		tc:RegisterEffect(e2)
		-- Change Name to "Galaxy-Eyes"
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_CHANGE_CODE)
		e3:SetValue(0x107b) -- Note: Directly assigns "Galaxy-Eyes" setcode-ready identification identity string
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY+RESET_OPPO_TURN)
		tc:RegisterEffect(e3)
	end
end

-- 5. End Phase Control & Material Absorb Logic
function s.xyzctlfilter(c)
	return c:IsType(TYPE_XYZ) and c:IsControlerCanBeChanged()
end
function s.ctltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.xyzctlfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,1-tp,LOCATION_MZONE)
end
function s.ctlop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectMatchingCard(tp,s.xyzctlfilter,tp,0,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	if tc and Duel.GetControl(tc,tp) then
		local og=Duel.GetMatchingGroup(Card.IsCanOverlay,tp,0,LOCATION_MZONE,nil)
		if #og>0 then
			Duel.BreakEffect()
			-- Standard EDOPro overlay function system handling safe attachment loops
			local remg=Group.CreateGroup()
			for oc in aux.Next(og) do
				local overlay_g=oc:GetOverlayGroup()
				if #overlay_g>0 then
					Duel.SendtoGrave(overlay_g,REASON_RULE)
				end
				remg:AddCard(oc)
			end
			Duel.Overlay(tc,remg)
		end
	end
end

-- 6. Standby Phase Banish & ATK Pump Logic
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end
s.rmfilter=aux.FilterBoolFunction(Card.IsType,TYPE_XYZ)
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE,0,1,99,nil)
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)~=0 then
		-- Count current number of your Xyz monsters in the banishment field space total
		local ct=Duel.GetMatchingGroupCount(function(bc) return bc:IsType(TYPE_XYZ) and bc:IsFaceup() end,tp,LOCATION_REMOVED,0,nil)
		if ct>0 and c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(ct*500)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end