--Borrel Reload
local s,id=GetID()

function s.initial_effect(c)

	--Activate (Allows the Continuous Spell to be played face-up)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--Activate effect
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--Grant effect to Borrel Link monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.eftg)
	e2:SetLabelObject(e2)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCountLimit(1)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetTarget(s.prottg)
	e3:SetOperation(s.protop)
	e2:SetLabelObject(e3)

end

-------------------------------------------------
--Target DARK monster to destroy
-------------------------------------------------

function s.desfilter(c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsDestructable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chk==0 then
		return Duel.IsExistingTarget(s.desfilter,tp,LOCATION_MZONE,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)

end

-------------------------------------------------
--Search logic
-------------------------------------------------

function s.thfilter(c)
	return c:IsAbleToHand() and (
		c:IsCode(00299524) -- Rapid Trigger
		or c:IsSetCard(0x102) -- Rokket
		or (c:IsType(TYPE_MONSTER) and c:IsSetCard(0x10f)) -- Borrel monsters
		or c:ListsArchetype(0x102) -- mentions Rokket
		or c:ListsArchetype(0x10f) -- mentions Borrel
	)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()

	if not tc or Duel.Destroy(tc,REASON_EFFECT)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)

	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end

end

-------------------------------------------------
--Grant effect to Borrel Links
-------------------------------------------------

function s.eftg(e,c)
	return c:IsSetCard(0x10f) and c:IsType(TYPE_LINK)
end

-------------------------------------------------
--Protection effect
-------------------------------------------------

function s.protfilter(c)
	return c:IsFaceup()
end

function s.prottg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then return chkc:IsOnField() and s.protfilter(chkc) end

	if chk==0 then
		return Duel.IsExistingTarget(s.protfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.protfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)

end

function s.protop(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsFaceup() then return end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(aux.tgoval)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)

	tc:RegisterEffect(e1)

end