local s,id=GetID()
function s.initial_effect(c)
	-- Activate the Continuous Spell Card itself
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- Ignition Effect: Target 1 LIGHT Machine Union to make it a Fusion Substitute
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(2,id) -- "You can only use 'Union Remodeling' twice per turn."
	e2:SetTarget(s.subtg)
	e2:SetOperation(s.subop)
	c:RegisterEffect(e2)
end

-- Filter for a face-up LIGHT Machine Union monster on your field
function s.tgfilter(c,tp)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_UNION)
		and Duel.IsExistingMatchingCard(s.revfilter,tp,LOCATION_EXTRA,0,1,nil)
end

-- Filter for a face-up LIGHT Machine Fusion monster to reveal
function s.revfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION)
end

-- 1. Target and Reveal validation
function s.subtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgfilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil,tp) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	
	-- Set up engine UI indicator for revealing from Extra Deck
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,tp,LOCATION_EXTRA)
end

-- 2. Effect Execution
function s.subop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	
	-- Reveal 1 LIGHT Machine Fusion monster from the Extra Deck
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.revfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local fcount=g:GetFirst()
	if not fcount then return end
	
	Duel.ConfirmCards(1-tp,g)
	local rev_code = fcount:GetCode() -- Capture the specific code of the revealed fusion card

	-- Inject the custom substitution effect into the targeted monster
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_FUSION_SUBSTITUTE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,1)) -- UI Hint: "Can be used as a substitute for a fusion material listed on the revealed monster"
	e1:SetCondition(s.subcon)
	e1:SetValue(s.subval)
	e1:SetLabel(rev_code) -- Pass along the revealed monster's card ID to the value check
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END) -- Lasts until the end of the turn
	tc:RegisterEffect(e1)
end

-- Check to ensure the substitution is only valid for the exact card name that was revealed
function s.subcon(e)
	return e:GetHandler():IsLocation(LOCATION_MZONE)
end

function s.subval(e,fc)
	-- If the fusion monster currently being selected in the game interface matches our label...
	if fc and fc:IsCode(e:GetLabel()) then
		-- "the other materials must be correct" rule built into the engine's core substitute handler
		return true
	end
	return false
end