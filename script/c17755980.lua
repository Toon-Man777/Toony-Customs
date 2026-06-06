local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: 3 LIGHT Level 8 monsters
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),8,3)
	c:EnableReviveLimit()

	-- Rule: Can only control 1 "The One Refracted By Zero, Galaxy-Eyes Cipher Dragon"
	c:SetUniqueOnField(1,0,id)

	-- Continuous: Unaffected by opponent's card effects while holding "Galaxy-Eyes Photon Dragon"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.imm_cond)
	e1:SetValue(s.imm_val)
	c:RegisterEffect(e1)

	-- Effect 1: When Xyz Summoned, search 1 "Galaxy", "Photon", or "Cipher" monster, AND Special Summon 1 LIGHT monster from hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SXYZ_SUMMON)
	e2:SetCountLimit(1,id) -- Hard once per turn
	e2:SetTarget(s.th_sp_tg)
	e2:SetOperation(s.th_sp_op)
	c:RegisterEffect(e2)

	-- Effect 2: Quick Effect battle step banish trick, can attack a second time, returns target at end of Battle Phase
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(TIMING_BATTLE_STEP)
	e3:SetCountLimit(1,id+100) -- Hard once per turn
	e3:SetCondition(s.ban_cond)
	e3:SetCost(aux.xyzcost)
	e3:SetTarget(s.ban_tg)
	e3:SetOperation(s.ban_op)
	c:RegisterEffect(e3)

	-- Effect 3: End Phase banish Xyz Monsters from GY to gain 500 ATK per Xyz Monster in banished zone
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+200) -- Hard once per turn
	e4:SetTarget(s.atk_tg)
	e4:SetOperation(s.atk_op)
	c:RegisterEffect(e4)
end

-- Official database codes for archetypes and named card
s.listed_names={93717133} -- "Galaxy-Eyes Photon Dragon"
s.listed_series={0x7b,0x93,0xe1} -- Galaxy (0x7b), Photon (0x93), Cipher (0xe1)

-- Immunity condition check (requires "Galaxy-Eyes Photon Dragon" as material)
function s.imm_cond(e)
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,93717133)
end
function s.imm_val(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- Filter for searching "Galaxy", "Photon", or "Cipher" monsters
function s.search_filter(c)
	return c:IsMonster() and (c:IsSetCard(0x7b) or c:IsSetCard(0x93) or c:IsSetCard(0xe1)) and c:IsAbleToHand()
end
-- Filter for summoning LIGHT monsters from hand
function s.sp_filter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_DEFENSE)
end

-- Effect 1 Handlers (Search + Special Summon)
function s.th_sp_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.search_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_HAND)
end
function s.th_sp_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.search_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		-- Then special summon 1 LIGHT monster from hand in defense position
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.sp_filter,tp,LOCATION_HAND,0,1,nil,e,tp) then
			if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sg=Duel.SelectMatchingCard(tp,s.sp_filter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
				if #sg>0 then
					Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_DEFENSE)
				end
			end
		end
	end
end

-- Effect 2 Handlers (Battle Step Banish and Second Attack)
function s.ban_cond(e,tp,eg,ep,ev,re,r,rp)
	-- Must be in the Battle Step, and this card must be the one battling
	return Duel.GetCurrentPhase()==PHASE_BATTLE_STEP and Duel.GetAttacker() and (Duel.GetAttacker()==e:GetHandler() or Duel.GetAttackTarget()==e:GetHandler())
end
function s.ban_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetHandler():GetBattleMonster()
	if chk==0 then return bc and bc:IsControler(1-tp) and bc:IsAbleToRemove() end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,bc,1,0,0)
end
function s.ban_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleMonster()
	if bc and bc:IsControler(1-tp) and Duel.Remove(bc,POS_FACEUP,REASON_EFFECT)~=0 then
		-- Gain a second attack
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_EXTRA_ATTACK)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
			c:RegisterEffect(e1)
		end
		-- Return the banished monster to opponent's field at the end of the Battle Phase
		if bc:IsLocation(LOCATION_REMOVED) then
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_PHASE+PHASE_BATTLE)
			e2:SetCountLimit(1)
			e2:SetLabelObject(bc)
			e2:SetCondition(s.ret_cond)
			e2:SetOperation(s.ret_op)
			e2:SetReset(RESET_PHASE+PHASE_BATTLE)
			Duel.RegisterEffect(e2,tp)
		end
	end
end
function s.ret_cond(e,tp,eg,ep,ev,re,r,rp)
	return e:GetLabelObject():IsLocation(LOCATION_REMOVED)
end
function s.ret_op(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.ReturnToField(tc)
end

-- Effect 3 Handlers (End Phase GY Banish to gain ATK)
function s.atk_gy_filter(c)
	return c:IsType(TYPE_XYZ) and c:IsMonster() and c:IsAbleToRemove()
end
function s.atk_ban_filter(c)
	return c:IsType(TYPE_XYZ) and c:IsMonster() and c:IsLocation(LOCATION_REMOVED)
end
function s.atk_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.atk_gy_filter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
end
function s.atk_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	-- Player chooses any number of Xyz monsters to banish from GY
	local g=Duel.SelectMatchingCard(tp,s.atk_gy_filter,tp,LOCATION_GRAVE,0,1,60,nil)
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)~=0 then
		-- Count all Xyz monsters in the banished zones globally
		local count=Duel.GetMatchingGroupCount(s.atk_ban_filter,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
		if count>0 and c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(count*500) -- Gains 500 ATK for each
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end