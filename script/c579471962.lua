local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: 2+ Level 1 Monsters
	-- FIXED: Changed the old max material value '99' to 'Xyz.InfiniteMats' to stop the crash
	Xyz.AddProcedure(c,nil,1,2,nil,nil,Xyz.InfiniteMats)
	c:EnableReviveLimit()

	-- Effect 1: Gains 300 ATK/DEF for each material attached
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	-- Effect 2: Detach 1 material; target 1 "Mokey Mokey" in GY and attach it as material
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCost(aux.xyzcost)
	e3:SetTarget(s.att_tg)
	e3:SetOperation(s.att_op)
	c:RegisterEffect(e3)

	-- Effect 3: If this card with material is destroyed: Special Summon "Mokey Mokey" tokens up to the number of materials it had
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.tok_cond)
	e4:SetTarget(s.tok_tg)
	e4:SetOperation(s.tok_op)
	c:RegisterEffect(e4)
end

s.listed_names={27288416,579471963} -- Mokey Mokey, Mokey Mokey Token ID

-- ATK/DEF Calculation based on materials
function s.atkval(e,c)
	return c:GetOverlayCount()*300
end

-- Filter for identifying valid "Mokey Mokey" targets in the GY
function s.att_filter(c)
	return (c:IsCode(27288416) or string.find(c:GetOriginalName() or "","Mokey Mokey")~=nil) and c:IsMonster()
end

-- Effect 2 Handlers (Attach from GY)
function s.att_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.att_filter(chkc) end
	if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) 
		and Duel.IsExistingTarget(s.att_filter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.att_filter,tp,LOCATION_GRAVE,0,1,1,nil)
end
function s.att_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
		Duel.Overlay(c,tc)
	end
end

-- Effect 3 Handlers (Token generation on destruction)
function s.tok_cond(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) and c:GetBanishParam()~=0 or c:GetPreviousOverlayCount()>0
end
function s.tok_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ct=e:GetHandler():GetPreviousOverlayCount()
		return ct>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>=ct
			and Duel.IsPlayerCanSpecialSummonMonster(tp,579471963,0,TYPES_TOKEN,0,0,1,RACE_FAIRY,ATTRIBUTE_LIGHT)
	end
	local ct=e:GetHandler():GetPreviousOverlayCount()
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,ct,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,ct,tp,0)
end
function s.tok_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=c:GetPreviousOverlayCount()
	if ct<=0 or Duel.GetLocationCount(tp,LOCATION_MZONE)<ct then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,579471963,0,TYPES_TOKEN,0,0,1,RACE_FAIRY,ATTRIBUTE_LIGHT) then return end
	
	for i=1,ct do
		local token=Duel.CreateToken(tp,579471963)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
	end
	Duel.SpecialSummonComplete()
end