local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon materials: 4 Level 9 Monsters
	Xyz.AddProcedure(c,nil,9,4)
	c:EnableReviveLimit()

	-- 1. Continuous Effect: Always treated as a "Number C" monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_ADD_SETCODE)
	e1:SetValue(0x1048) -- "Number C" archetype setcode
	c:RegisterEffect(e1)

	-- 2. Trigger Effect: When Xyz Summoned, Special Summon 1 WATER Plant, then you can Tribute 1 monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- 3. Quick Effect: Detach 1, Tribute 1 monster, Negate 1 opponent's monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_RELEASE+CATEGORY_DISABLE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e3:SetCost(Xyz.CutCost(1)) -- Universally safe material detach cost helper
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	-- 4. Continuous Effect: Opponent pays 500 LP every time their monster is Tributed
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_RELEASE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetOperation(s.lpop)
	c:RegisterEffect(e4)

	-- 5. Continuous Effect: WATER Plant monsters gain 200 ATK each time a monster is tributed
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_RELEASE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetOperation(s.atkop)
	c:RegisterEffect(e5)
end

-- 2. Xyz Summon Trigger Logic
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_PLANT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_ATTACK)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_ATTACK)~=0 then
		local tg=Duel.GetMatchingGroup(Card.IsReleasableByEffect,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		if #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
			local sg=tg:Select(tp,1,1,nil)
			Duel.Release(sg,REASON_EFFECT)
		end
	end
end

-- 3. Quick Effect Target/Negate Logic
function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.negfilter(chkc) end
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsReleasableByEffect,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
		and Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=Duel.SelectMatchingCard(tp,Card.IsReleasableByEffect,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	
	if #rg>0 and Duel.Release(rg,REASON_EFFECT)~=0 then
		if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
			Duel.BreakEffect()
			Duel.NegateRelatedChain(tc,RESET_TURN_SET)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end

-- 4. Burn Tax Execution
function s.lpfilter(c,tp)
	return c:IsPreviousControler(1-tp) and c:IsPreviousLocation(LOCATION_MZONE)
end
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	local count=eg:FilterCount(s.lpfilter,nil,tp)
	if count>0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.PayLPCost(1-tp,count*500)
	end
end

-- 5. Permanent Attack Buff Logic
function s.atkfilter(c)
	return c:IsPreviousLocation(LOCATION_MZONE)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local count=eg:FilterCount(s.atkfilter,nil)
	if count<=0 then return end
	
	local c=e:GetHandler()
	local tg=Duel.GetMatchingGroup(function(mc) return mc:IsFaceup() and mc:IsAttribute(ATTRIBUTE_WATER) and mc:IsRace(RACE_PLANT) end,tp,LOCATION_MZONE,0,nil)
	
	if #tg>0 then
		Duel.Hint(HINT_CARD,0,id)
		for tc in aux.Next(tg) do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(count*200)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end