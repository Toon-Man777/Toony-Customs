local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon 1 LIGHT Machine monster
	local e1=Fusion.CreateSummonEff({
		handler=c,
		filter=s.ffilter,
		matfilter=Fusion.OnFieldMat(Card.IsAbleToGraveAsCost),
		extrafil=s.fextra,
		extraop=Fusion.ShuffleSelf,
		extratg=s.extratarget,
		stage2=s.stage2
	})
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)

	-- Banish from GY to recycle 1 "Satellite" card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Filter for LIGHT Machine Fusion Monsters
function s.ffilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION)
end

-- Allow using 1 Level 5 LIGHT Machine from Deck as material
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(s.exfilter,tp,LOCATION_DECK,0,nil),s.fcheck
end
function s.exfilter(c)
	return c:IsLevel(5) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsAbleToGrave()
end
function s.fcheck(tp,sg,fc)
	return sg:FilterCount(Card.IsLocation,nil,LOCATION_DECK)<=1
end

-- GY Recycling for "Satellite" cards
function s.thfilter(c)
	return c:IsSetCard(0x10cf) and c:IsAbleToHand() and not c:IsCode(id)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end