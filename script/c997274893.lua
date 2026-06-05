local s,id=GetID()
function s.initial_effect(c)
	-- Equip Procedure
	aux.AddEquipProcedure(c,nil,s.eqfilter)

	-- 1. Continuous Effect: Gains ATK/DEF equal to its Level x 300 (UPDATED)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.val)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	-- 2. Continuous Effect: Piercing Battle Damage
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e3)

	-- 3. Continuous Effect: Substitution Destruction Protection
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_EQUIP)
	e4:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e4:SetValue(s.repval)
	c:RegisterEffect(e4)

	-- 4. GY Ignition Effect: Banish to recycle 1 LIGHT Machine Fusion, then search a listed Material from Deck/Banished
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_TOEXTRA+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_GRAVE)
	e5:SetCountLimit(1,id)
	e5:SetCost(aux.bfgcost)
	e5:SetTarget(s.thtg)
	e5:SetOperation(s.thop)
	c:RegisterEffect(e5)
end

-- Equip Target Requirement Validation
function s.eqfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION)
end

-- Stat Calculation Logic (Updated to x 300 multiplier)
function s.val(e,c)
	return c:GetLevel()*300
end

-- Substitution Logic
function s.repval(e,re,r,rp)
	return (r&REASON_EFFECT+REASON_BATTLE)~=0
end

-- 4. GY Recovery & Material Search Logic
function s.exfilter(c,tp)
	if not (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FUSION) and c:IsLevelAbove(6) and c:IsAbleToExtra()) then return false end
	if not c.listed_names or #c.listed_names==0 then return false end
	
	local mats=c.listed_names
	return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,mats)
end
function s.thfilter(c,mats)
	if not (c:IsAbleToHand() and (c:IsType(TYPE_NORMAL) or c:IsType(TYPE_UNION))) then return false end
	for _, code in ipairs(mats) do
		if c:IsCode(code) then return true end
	end
	return false
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.exfilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.exfilter,tp,LOCATION_GRAVE,0,1,nil,tp) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.exfilter,tp,LOCATION_GRAVE,0,1,1,nil,tp)
	
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc.listed_names and #tc.listed_names > 0 then
		local mats=tc.listed_names
		if Duel.SendtoExtra(tc,nil,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_EXTRA) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,mats)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end