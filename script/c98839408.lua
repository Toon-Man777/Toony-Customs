local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon Procedure: 1 Tuner + 1+ non-Tuners
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	-- 0. Always treated as an "Ice Barrier" card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x2f) -- Ice Barrier Archetype Hex
	c:RegisterEffect(e0)

	-- 1. When Synchro Summoned: Add 1 "Cursed" card from Deck to Hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Negate activation and SS a clone from Extra Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_BUFF)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1) -- Hard once per turn rule applied to this effect tracking
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- 3. Banish generic Spells from GY to buff WATER Fiend Synchros
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+2)
	e3:SetCost(s.effcost)
	e3:SetOperation(s.effop)
	c:RegisterEffect(e3)
end

-- Name constant for Extra Deck clone tracking
s.shake_name = "Cursed With Pride, Frozen Jokester Shakespeare"

-- Effect 1: Archetype-wide search
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.thfilter(c)
	return c:IsSetCard(0x923) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Effect 2: Negate & Extra Deck Summon Engine
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.ssfilter(c,e,tp)
	return c:IsCleanName(s.shake_name) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ssfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.ssfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)~=0 then
		Duel.NegateActivation(ev)
	end
end

-- Effect 3: Banish Spells for Tiered Combat Traits
function s.costfilter(c)
	return c:IsSpell() and c:IsAbleToRemoveAsCost() -- Bug fix fixated: Native removal verification rule
end
function s.effcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE,0,1,99,nil)
	local count=Duel.Remove(g,POS_FACEUP,REASON_COST)
	e:SetLabel(count)
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local count=e:GetLabel()
	if count==0 then return end

	-- Aura filter targeting rule: Face-up WATER Fiend Synchro Monsters
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.synchrofilter)
	e1:SetValue(s.atkval)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- 2+ Banished items checked
	if count >= 2 then
		-- Attack twice per turn
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_EXTRA_ATTACK)
		e2:SetTargetRange(LOCATION_MZONE,0)
		e2:SetTarget(s.synchrofilter)
		e2:SetValue(1)
		e2:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e2,tp)

		-- Banish monsters destroyed by battle
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetCode(EFFECT_BATTLE_DESTROY_REDIRECT)
		e3:SetTargetRange(LOCATION_MZONE,0)
		e3:SetTarget(s.synchrofilter)
		e3:SetValue(LOCATION_REMOVED)
		e3:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e3,tp)
	end

	-- 3+ Banished items checked
	if count >= 3 then
		-- Unaffected by opponent's card effects
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_FIELD)
		e4:SetCode(EFFECT_IMMUNE_EFFECT)
		e4:SetTargetRange(LOCATION_MZONE,0)
		e4:SetTarget(s.synchrofilter)
		e4:SetValue(s.immunefilter)
		e4:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e4,tp)

		-- Target battle destruction hook to trigger card effect negation
		local e5=Effect.CreateEffect(c)
		e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e5:SetCode(EVENT_BATTLE_DESTROYING)
		e5:SetCondition(s.negatetrcon)
		e5:SetOperation(s.negateterop)
		e5:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e5,tp)
	end
end

-- Target checking filters
function s.synchrofilter(e,c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_FIEND) and c:IsType(TYPE_SYNCHRO)
end
function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()
	-- Dynamic loop matching checking duplicate names face-up on field
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local count=0
	for tc in aux.Next(g) do
		if tc:IsCleanName(c:GetCleanName()) then
			count = count + 1
		end
	end
	return count * 1000
end
function s.immunefilter(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- Tier 3 continuous operational loops
function s.negatetrcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	return tc and tc:IsControler(tp) and s.synchrofilter(e,tc) and tc:IsRelateToBattle()
end
function s.negateterop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) 
		and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
		local g=Duel.SelectMatchingCard(tp,Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			local tc=g:GetFirst()
			local c=e:GetOwner()
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