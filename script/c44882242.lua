-- Dark Resurgence
local s,id=GetID()
function s.initial_effect(c)
	-- Draw and Return to Hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	
	-- Extra Normal Summon (GY Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.nscon)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.nsop)
	c:RegisterEffect(e2)
end

-- Activation Condition: Less LP than opponent OR No cards in hand
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(tp) < Duel.GetLP(1-tp) or Duel.GetFieldGroupCount(tp,LOCATION_HAND,0) == 0
end

-- Filter for different named DARK Spellcasters
function s.drawfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_SPELLCASTER)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.drawfilter,tp,LOCATION_MZONE,0,nil)
		local ct=g:GetClassCount(Card.GetCode)
		return ct > 0 and Duel.IsPlayerCanDraw(tp,ct)
	end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.drawfilter,tp,LOCATION_MZONE,0,nil)
	local ct=g:GetClassCount(Card.GetCode)
	if ct > 0 and Duel.Draw(tp,ct,REASON_EFFECT) > 0 then
		-- Return monsters until you control 1
		local mg=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,LOCATION_MZONE,0,nil)
		if #mg > 1 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
			local sg=mg:Select(tp,#mg-1,#mg-1,nil)
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
		end
		
		-- Restriction: Cannot draw or add from Deck
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetDescription(aux.Stringid(id,2)) -- "Cannot draw/add from Deck"
		e1:SetCode(EFFECT_CANNOT_DRAW)
		e1:SetTargetRange(1,0)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CANNOT_TO_HAND)
		e2:SetTarget(s.thlimit)
		Duel.RegisterEffect(e2,tp)
	end
end

function s.thlimit(e,c,tp,re)
	return c:IsLocation(LOCATION_DECK) and re and re:IsHasType(EFFECT_TYPE_ACTIONS)
end

-- Extra Normal Summon Logic
function s.nscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,46986414),tp,LOCATION_ONFIELD,0,1,nil)
end

function s.nsop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTarget(s.nstg)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.nstg(e,c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_SPELLCASTER)
end