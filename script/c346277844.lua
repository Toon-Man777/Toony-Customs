local s,id=GetID()
function s.initial_effect(c)
	c:EnableCounterPermit(0x104b)

	-- Activation: Add 1 "Meklord" card from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Continuous: Treat opposing monsters as Synchro
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_ADD_TYPE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCondition(s.synccon)
	e2:SetValue(TYPE_SYNCHRO)
	c:RegisterEffect(e2)

	-- Trigger: Place 1 Feast Counter when a "Meklord Emperor" monster activates an effect
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_FZONE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetOperation(s.ctop)
	c:RegisterEffect(e3)

	-- Continuous Substitute: Remove 1 Counter to prevent Machine destruction
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
end

function s.thfilter(c)
	return c:IsSetCard(0x13) and c:IsAbleToHand() -- 0x13 = "Meklord"
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingCardGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x13) and c:IsType(TYPE_MONSTER)
end
function s.synccon(e)
	return Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	-- Verified condition: Checks if the activated effect belongs to a monster belonging to 0x3013 ("Meklord Emperor")
	if re:IsActiveType(TYPE_MONSTER) and rc:IsFaceup() and rc:IsLocation(LOCATION_MZONE) and rc:IsSetCard(0x3013) then
		e:GetHandler():AddCounter(0x104b,1)
	end
end

function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsLocation(LOCATION_MZONE) and c:IsRace(RACE_MACHINE)
		and c:IsControler(tp) and not c:IsReason(REASON_REPLACE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x104b,1,REASON_EFFECT)
		and eg:IsExists(s.repfilter,1,nil,tp) end
	if Duel.SelectEffectYesNo(tp,e:GetHandler(),aux.Stringid(id,2)) then
		local g=eg:Filter(s.repfilter,nil,tp)
		if #g>1 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESREPLACE)
			g=g:Select(tp,1,1,nil)
		end
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.repval(e,c)
	local g=e:GetLabelObject()
	return g and g:IsContains(c)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RemoveCounter(tp,0x104b,1,REASON_EFFECT)
	local g=e:GetLabelObject()
	if g then
		g:DeleteGroup()
	end
end