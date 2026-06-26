--Great Zero Magic, Numerical Shift
function c17755990.initial_effect(c)
local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Reveal 1 "Zero" Monster from Deck/Extra Deck to Special Summon it (ignoring conditions)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) -- Hard OPT
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effect 2: GY Banish + Pay Half LP: Target 1 "Zero" Xyz Monster, Reveal 10 differently named monsters to attach
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100) -- Hard OPT
	e2:SetCost(s.matcost)
	e2:SetTarget(s.mattg)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)
end

-- Using the native 0xf00 archetype hex check
function s.zerofilter(c)
	return c:IsSetCard(0xf00)
end

-- Effect 1 Logic
function s.spfilter(c,e,tp)
	return s.zerofilter(c) and c:IsMonster() and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.ConfirmCards(1-tp,g)
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end

-- Effect 2 Logic
function s.matcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
	Duel.PayLPCost(tp,Duel.GetLP(tp)/2)
end
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and s.zerofilter(c)
end
function s.revfilter(c)
	return c:IsMonster()
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.xyzfilter(chkc) end
	if chk==0 then 
		local rg=Duel.GetMatchingGroup(s.revfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA,0,nil)
		return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
			and rg:GetClassCount(Card.GetCode)>=10
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) then return end
	
	local rg=Duel.GetMatchingGroup(s.revfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA,0,nil)
	if rg:GetClassCount(Card.GetCode)<10 then return end
	
	-- Select 10 monsters with different names from Hand, Deck, or Extra Deck
	local matg=Group.CreateGroup()
	for i=1,10 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg=rg:Select(tp,1,1,nil)
		matg:Merge(sg)
		rg:Remove(Card.IsCode,nil,sg:GetFirst():GetCode())
	end
	
	if #matg==10 then
		Duel.ConfirmCards(1-tp,matg)
		-- Attach all 10 to the target monster
		Duel.Overlay(tc,matg)
	end
end