local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon materials: 3 LIGHT Level 8 monsters
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),8,3)
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

	-- 4. Quick Effect: Battle Step temporary banish + second attack
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1000000)
	e3:SetCondition(s.bcon)
	e3:SetCost(Xyz.CutCost(1))
	e3:SetTarget(s.btg)
	e3:SetOperation(s.bop)
	c:RegisterEffect(e3)

	-- 5. Trigger Effect: During the End Phase, banish Xyz monsters from GY to gain ATK
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+2000000)
	e4:SetTarget(s.atktg)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)
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
			and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
			if #sg>0 then
				Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
			end
		end
	end
end

-- 4. Battle Step Temporary Banish Logic
function s.bcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Strictly verifies we are inside the Battle Step and battling an opponent's monster
	return Duel.GetCurrentPhase()==PHASE_BATTLE_STEP and (Duel.GetAttacker()==c or Duel.GetAttackTarget()==c)
end
function s.btg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()
	if chk==0 then return tc and tc:IsAbleToRemove() end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,tc,1,0,0)
end
function s.bop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()
	if tc and tc:IsRelateToBattle() and Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)~=0 then
		-- Apply Second Attack logic safely
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EXTRA_ATTACK)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
			c:RegisterEffect(e1)
		end
		-- Set up lingering return handler system to bring back the monster at the end of the Battle Phase
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(EVENT_PHASE+PHASE_BATTLE)
		e2:SetCountLimit(1)
		e2:SetLabelObject(tc)
		e2:SetCondition(s.retcon)
		e2:SetOperation(s.retop)
		e2:SetReset(RESET_PHASE+PHASE_BATTLE)
		Duel.RegisterEffect(e2,tp)
	end
end
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	return tc and tc:IsLocation(LOCATION_REMOVED)
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.ReturnToField(tc)
end

-- 5. End Phase Banish & ATK Pump Logic
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
		-- Counts total Xyz monsters currently residing face-up in your banishment
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