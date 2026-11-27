-- Firewallcode Talker
-- ID: 65962310
local s, id = GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Link Summon procedure: 2+ Effect monsters (Link-4)
	Link.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsType, TYPE_EFFECT), 2, 4)

	-- Effect 1: Gains 500 ATK for each card this card points to
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- Effect 2: Quick negate + tribute 1 monster this card points to + return to hand
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_NEGATE + CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- Effect 3: If destroyed, Special Summon 1 "Firewall" monster from GY except "Firewallcode Talker"
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1, id + 100)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- Helper: Check if a monster is a valid Tribute this card points to
function s.cfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsReleasable()
end

-- ATK Calculation: 500 per card this card points to
function s.atkval(e, c)
	return c:GetLinkedGroupCount() * 500
end

-- Negate Condition: Opponent activates a card effect, and this card points to at least 1 tributable monster
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	return rp == 1 - tp and Duel.IsChainNegatable(ev)
		and e:GetHandler():GetLinkedGroup():IsExists(s.cfilter, 1, nil)
end

-- Negate Cost: Tribute 1 monster this card points to
function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local lg = e:GetHandler():GetLinkedGroup():Filter(s.cfilter, nil)
	if chk == 0 then return #lg > 0 end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
	local g = lg:Select(tp, 1, 1, nil)
	Duel.Release(g, REASON_COST)
end

-- Negate Target: Set operation info for negation and returning to hand if applicable
function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0, CATEGORY_TOHAND, eg, 1, 0, 0)
	end
end

-- Negate Operation: Negate activation, and if negated, return that card to the hand
function s.negop(e, tp, eg, ep, ev, re, r, rp)
	local rc = re:GetHandler()
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		Duel.SendtoHand(rc, nil, REASON_EFFECT)
	end
end

-- Special Summon Filter: "Firewall" monster in GY, except "Firewallcode Talker" (65962310)
function s.spfilter(c, e, tp)
	return c:IsSetCard(0x190) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
		and not c:IsCode(id)
end

-- Special Summon Target
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end

-- Special Summon Operation
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	if #g > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end